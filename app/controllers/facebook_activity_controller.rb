class FacebookActivityController < ApplicationController

  #method post_wall:post a message to user's wall
  def post_wall

    @user_id = current_user.id #find out the current user
    @authentication = Authentication.find_by_user_id( @user_id )

    me = FbGraph::User.me(@authentication.token)
    me.feed!(
      :message => 'I am Learning on MINE_LMS now, and I am learning',
      :picture => 'https://graph.facebook.com/matake/picture',
      :link => 'http://litopon.minelab.tw/courses',
      :name => 'MINELab Learning Management System',
      :description => 'An Excellent Learning Management System Developed by MINE Lab @ NCU'
    )
  end

  #method action_wall: custom action "study"
  def action_wall

    @user_id = current_user.id #find out the current user
    @authentication = Authentication.find_by_user_id( @user_id )

    app = FbGraph::Application.new(373518166042529)
    me = FbGraph::User.me(@authentication.token)

    action = me.og_action!(
      app.og_action( :study),
      :course => 'http://litopon.mine.csie.ncu.edu.tw/courses'
    )
  end

  #method get_fb_friends: get the user's friends and store in the user table
  def get_fb_friends

    @user_id = current_user.id #find out the current user
    @authentication = Authentication.find_by_user_id( @user_id )

    me = FbGraph::User.me( @authentication.token )
    @data = me.friends
    @friends = Array.new()

    for i in 0...(@data.length)
      @friends[i] = { :name => @data[i].raw_attributes['name'], :uid => @data[i].raw_attributes['id'] }
    end

    @user = User.find( @user_id )
    @user.friend = @friends
    @user.save
  end
  
  def send_data_to_3D
    ActiveRecord::Base.include_root_in_json = true

    #@user = User.find_by_email( current_user.email )
    @user = User.find_by_fb_id( 100003952381304 )
    @courses = Course.all
    @course_list = Array.new([@courses.length])
    @courses_tree = Array.new()

    #find out the course tree
    @courses.each_with_index do |c, index|
      require 'open-uri'

      #find out the imsmanifest file and parse the organization/item part
      @course = Course.find( c.id )
      @uri = @course.courseURL + "imsmanifest.xml"
      @imsmanifest = open(@uri).read
      @doc = Nokogiri::XML(@imsmanifest)
      @modules = @doc.css('//organizations/organization/item')
      @resources = @doc.css('//resources/resource')

      #store the parsed data in to an array
      @course_tree = Array.new()
      @index = 0

      @modules.each_with_index do |m, i|
        @lesson_tree = Array.new()
        @lessons = m.css('/item')
        @file = "none"
        #if there is no child under the item
        if @lessons.empty?
          @resources.each do |r|
            if r['identifier'] == m['identifierref']
              @file = r['href']
            end
            #check this lesson is read or not
            @read_flag = false
            @history = UserLearningHistory.all( :conditions => { :user_id => @user.id, :course_id => @course.id, :lesson => @file } )
            if @history.empty?
              @read_flag = false
            else
              @read_flag = true
            end

            @course_tree[i] = { :module_name => m.css('/title').text, :lesson_tree => @lesson_tree, :lesson_file => @file, :read_flag => @read_flag }
          end
        #if there is child under the item
        else
          @lessons.each_with_index do |l, j|
            @temp = l.css('/title')
            @resources.each do |r|
              if r['identifier'] == l['identifierref']
                @file = r['href']
              end
              #check this lesson is read or not
              @read_flag = false
              @history = UserLearningHistory.all( :conditions => { :user_id => @user.id, :course_id => @course.id, :lesson => @file } )
              if @history.empty?
                @read_flag = false
              else
                @read_flag = true
              end

              @lesson_tree[j] = { :lesson_name => @temp.text, :lesson_file => @file, :read_flag => @read_flag }
            end
          end
          @course_tree[i] = { :module_name => m.css('/title').text, :lesson_tree => @lesson_tree }
        end
      end
      @courses_tree[index] = @course_tree
    end

    #find out the current user and his learning progress
    for i in 0...(@courses.length)
      @course = Course.find(i+1)
      @temp = UserCourseRelationship.all( :conditions => { :user_id => @user.id, :course_id => @course.courseID} )

      if @temp.empty?
        @courseCurrent = "none"
      else
        @courseCurrent = @temp[0]["courseCurrent"]
      end

      @course_list[i] =  { :courseID => @course.courseID, :courseName => @course.courseName, :courseStatus => @course.courseStatus,
                           :courseURL => @course.courseURL, :courseCurrent => @courseCurrent, :courseTree => @courses_tree[i] }
    end

    #find out the current user's friend and their learning progress
    @friend_list = Array.new([@user.friend.length])
    @friend_course_list = Array.new([@courses.length])
    for i in 0...(@user.friend.length)
      #find out the current user's friend
      @uid = @user.friend[i][ :uid]
      @user_friend = User.find_by_fb_id( @uid )

      #find out the current user's friend's learning progress
      for j in 0...(@courses.length)
        @course = Course.find(j+1)
        @temp = UserCourseRelationship.all( :conditions => { :user_id => @user_friend.id, :course_id => @course.id } )

        if @temp.empty?
          @courseCurrent = "none"
        else
          @courseCurrent = @temp[0]["courseCurrent"]
        end
      
        @friend_course_list[j] =  { :courseID => @course.courseID, :courseName => @course.courseName, :courseStatus => @course.courseStatus,
                                    :courseURL => @course.courseURL,:courseCurrent => @courseCurrent }
      end

      #store each friend's information and learning progress in friend_list array
      @friend_list[i] = { :friendID => @user_friend.email, :friend_course_list => @friend_course_list }
    end

    #make a json object with the course_list array
    @json_object = ActiveSupport::JSON.encode( {  :userID => @user.email, :course_list => @course_list, :friend_list => @friend_list  } )


    #method send_data: send a streaming data to client, and :disposition determines the type of file(attachment file or inline file)
    send_data @json_object, :type => "application/json", :disposition => "inline"

  end
end
