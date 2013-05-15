class FacebookActivityController < ApplicationController

  #method post_wall:post a message to user's wall
  def post_wall

    @post_content = params[ :post_content]

    @user_id = current_user.id #find out the current user
    @authentication = Authentication.find_by_user_id( @user_id )

    me = FbGraph::User.me(@authentication.token)
    me.feed!(
      :message => @post_content.to_s,
      :picture => 'https://graph.facebook.com/matake/picture',
      :link => 'http://litopon.minelab.tw/courses',
      :name => 'MINELab Learning Management System',
      :description => 'An Excellent Learning Management System Developed by MINE Lab @ NCU'
    )

    respond_to do |format|
      format.html
    end#respond end

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
    @user = User.find(@user_id)
    @authentication = Authentication.find_by_user_id( @user_id )
    @user.fb_id = @authentication.uid

    @friend_data = HTTParty.get('https://graph.facebook.com/' + @user.fb_id + '?fields=friends.fields(picture,email,name)&access_token=' + @authentication.token )
    @friends = Array.new()
    @close_friends = Array.new()
    @acquaintance_friends = Array.new()

    #get the friend list
    @friend_list_url = HTTParty.get('https://graph.facebook.com/me/friendlists?access_token=' + @authentication.token )
    #get the close friend list and acquaintances list
    @friend_list_url['data'].each do |list|
      if list['list_type'] == "close_friends"
        @close_id = list['id']
      end
      if list['list_type'] == "acquaintances"
        @acquaintance_id = list['id']
      end
    end

    #store close friend
    @close_friend_list = HTTParty.get('https://graph.facebook.com/' + @close_id + '/members?access_token=' + @authentication.token )
    @close_friend_list['data'].each_with_index do |cf, index|
      @close_friends[index] = cf['id']
    end

    #store acquaintance friend
    @acquaintance_friend_list = HTTParty.get('https://graph.facebook.com/' + @acquaintance_id + '/members?access_token=' + @authentication.token )
    @acquaintance_friend_list['data'].each_with_index do |af, index|
      @acquaintance_friends[index] = af['id']
    end
    
    @friend_data['friends']['data'].each_with_index do |fd, index|
      #store the friend data
      @friends[index] = { :name => fd['name'], :uid => fd['id'], :friend_type => "1", :picture => fd['picture']['data']['url'] }

      #check the friend is close friend or not
      @close_friends.each do |cf|
        if fd['id'] == cf
          @friends[index] = { :name => fd['name'], :uid => fd['id'], :friend_type => "3", :picture => fd['picture']['data']['url'] }
        end
      end
      #check the friend is acquaintance or not
      @acquaintance_friends.each do |af|
        if fd['id'] == af
          @friends[index] = { :name => fd['name'], :uid => fd['id'], :friend_type => "2", :picture => fd['picture']['data']['url'] }
        end
      end
    end

    #@user = User.find( @user_id )
    @user.friend = @friends
    @user_data = HTTParty.get('https://graph.facebook.com/' + @user.fb_id + '?fields=picture,name' )
    @user.name = @user_data['name']
    @user.picture = @user_data['picture']['data']['url']
    @user.save

    render :json => @user.friend
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
      @friend_list[@index_friend] = { :friendID => @user_friend.email, :friend_type => @user.friend[i][ :friend_type],
                                      :friend_course_list => @friend_course_list }
      @index_friend += 1
    end

    #make a json object with the course_list array
    @json_object = ActiveSupport::JSON.encode( {  :userID => @user.email, :course_list => @courses, :friend_list => @friend_list  } )

    #render :json => @json_object
    send_data @json_object, :type => "application/json", :disposition => "inline"
  end
    
end
