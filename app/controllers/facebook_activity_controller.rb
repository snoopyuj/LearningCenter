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
    @close_friends = Array.new()

    #get the close friend list
    @close_friend_url = HTTParty.get('https://graph.facebook.com/me/friendlists?access_token=' + @authentication.token )
    @close_friend_list_id = @close_friend_url['data'][2]['id']
    @close_friend_list = HTTParty.get('https://graph.facebook.com/' + @close_friend_list_id + '/members?access_token=' + @authentication.token )

    #store close friend
    @close_friend_list['data'].each_with_index do |cf, index|
      @close_friends[index] = cf['id']
    end

    for i in 0...(@data.length)
      @close_flag = false
      #check the friend is close friend or not
      @close_friends.each do |cf|
        if @data[i].raw_attributes['id'] == cf
          @close_flag = true
        end
      end
      #store the friend data
      @friends[i] = { :name => @data[i].raw_attributes['name'], :uid => @data[i].raw_attributes['id'], :close_friend => @close_flag }
    end

    @user = User.find( @user_id )
    @user.friend = @friends
    @user.save
  end

  def send_data_to_3D
    @user = User.find_by_fb_id( 100003952381304 )
    @courses = Course.all
    @course_list = Array.new([@courses.length])

    #find out the current user's learning progress and learning history  
    for i in 0...@courses.length
      next if @courses[i].nil?
      #get learning history
      get_read_flag( @user.id, @courses[i].id, @courses[i].course_tree )

      #get learning progress
      @temp = UserCourseRelationship.all( :conditions => { :user_id => @user.id, :course_id => @courses[i].id } )
      if @temp.empty?
        @courses[i].courseCurrent = "none"
      else
        @courses[i].courseCurrent = @temp[0]["courseCurrent"]
      end
    end

    #find out the current user's friend and their learning progress
    @friend_list = Array.new([@user.friend.length])
    @friend_course_list = Array.new([@courses.length])
    @index_friend = 0
    for i in 0...(@user.friend.length)
      #find out the current user's friend
      @uid = @user.friend[i][ :uid]
      @user_friend = User.find_by_fb_id( @uid )
      next if @user_friend.nil?

      #find out the current user's friend's learning progress
      @index_course = 0
      for j in 0...(@courses.length)
        @course = Course.find_by_id(j+1)
        next if @course.nil?
        @temp = UserCourseRelationship.all( :conditions => { :user_id => @user_friend.id, :course_id => @course.courseID } )

        if @temp.empty?
          @courseCurrent = "none"
        else
          @courseCurrent = @temp[0]["courseCurrent"]
        end

        @friend_course_list[@index_course] =  { :courseID => @course.courseID, :courseName => @course.courseName, :courseStatus => @course.courseStatus,
                                                :courseURL => @course.courseURL,:courseCurrent => @courseCurrent }
        @index_course += 1
      end

      #store each friend's information and learning progress in friend_list array
      @friend_list[@index_friend] = { :friendID => @user_friend.email, :close_friend => @user.friend[i][ :close_friend],
                                      :friend_course_list => @friend_course_list }
      @index_friend += 1
    end

    #make a json object with the course_list array
    @json_object = ActiveSupport::JSON.encode( {  :userID => @user.email, :course_list => @courses, :friend_list => @friend_list  } )


    render :json => @json_object
  end
    
  def send_data_to_3D_test
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
      @course = Course.find_by_id(i+1)
      next if @course.nil?
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
    @index_friend = 0
    for i in 0...(@user.friend.length)
      #find out the current user's friend
      @uid = @user.friend[i][ :uid]
      @user_friend = User.find_by_fb_id( @uid )
      next if @user_friend.nil?

      #find out the current user's friend's learning progress
      @index_course = 0
      for j in 0...(@courses.length)
        @course = Course.find_by_id(j+1) 
        next if @course.nil?
        @temp = UserCourseRelationship.all( :conditions => { :user_id => @user_friend.id, :course_id => @course.courseID } )

        if @temp.empty?
          @courseCurrent = "none"
        else
          @courseCurrent = @temp[0]["courseCurrent"]
        end
      
        @friend_course_list[@index_course] =  { :courseID => @course.courseID, :courseName => @course.courseName, :courseStatus => @course.courseStatus,
                                                :courseURL => @course.courseURL,:courseCurrent => @courseCurrent }
        @index_course += 1
      end

      #store each friend's information and learning progress in friend_list array
      @friend_list[@index_friend] = { :friendID => @user_friend.email, :close_friend => @user.friend[i][ :close_friend], 
                                      :friend_course_list => @friend_course_list }
      @index_friend += 1
    end

    #make a json object with the course_list array
    @json_object = ActiveSupport::JSON.encode( {  :userID => @user.email, :course_list => @course_list, :friend_list => @friend_list  } )


    #method send_data: send a streaming data to client, and :disposition determines the type of file(attachment file or inline file)
    send_data @json_object, :type => "application/json", :disposition => "inline"

  end
end
