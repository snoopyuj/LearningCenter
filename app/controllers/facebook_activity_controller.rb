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

    for i in 0...(@data.length-1)
      @friends[i] = { :name => @data[i].raw_attributes['name'], :uid => @data[i].raw_attributes['id'] }
    end

    @user = User.find( @user_id )
    @user.friend = @friends 
    @user.save
  
    @test = User.find(@user.id)
  end
end
