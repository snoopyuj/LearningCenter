class ApplicationController < ActionController::Base
  protect_from_forgery

  #test 
  def parse_node_general_version( node, resources, result = [] )
    @check = node.css('/item')
  
    #if the node has no children
    if @check.empty?
      @file = "none"
      resources.each do |r|
        if r['identifier'] == node['identifierref']
          @file = r['href']
        end
      end
      @return_value = { :node_title => node.css('/title').text, :node_file => @file, :node_items => "none" }
      return @return_value
    #if the node has no child
    else
      @temp_array = Array.new()
      @check.each_with_index do |item, index|
        @temp = parse_node_general_version( item, resources, @temp_array )
        if @temp.is_a? (Array)
          result[index] = { :node_title => item.css('/title').text, :node_file => "none", :node_items => @temp  }
        else
          result[index] = { :node_title => @temp[ :node_title], :node_file => @temp[ :node_file], :node_items => "none"}
        end
      end
      return result
    end
  end

  #parse the course tree
  def parse_node( node, resources, result = [] )
    require 'scorm2004-manifest'

    #if the node has no child
    if node.items.empty?
      @file = "none"
      @resources.each do |r|
        if r.identifier == node.identifierref
          @file = r.href
        end
      end
      @return_value = { :node_title => node.title.content, :node_file => @file, :node_items => "none" }
      return @return_value
    #if the node has children
    else
      @temp_array = Array.new()
      node.items.each_with_index do |item, index|
        @temp = parse_node( item, resources, @temp_array )
        if @temp.is_a? (Array)
          result[index] = { :node_title => item.title.content, :node_file => "none", :node_items => @temp  }
        else
          result[index] = { :node_title => @temp[ :node_title], :node_file => @temp[ :node_file], :node_items => "none"}
        end
       end
      return result
    end
  end

  #get_read_flag
  def get_read_flag( user_id, course_id, node )
    node.each do |nd|
      if nd[ :node_items].is_a? (Array)
        get_read_flag( user_id, course_id, nd[ :node_items] )
      else
        puts nd[ :node_file]
        @read_flag = false
        @history = UserLearningHistory.all( :conditions => { :user_id => user_id, :course_id => course_id, :lesson => nd[ :node_file] } )

        if @history.empty?
          @read_flag = false
        else
          @read_flag = true
        end
        nd[ :read_flag] = @read_flag
      end
    end
  end

  #count_learning_flag
  def count_learning_flag( user_id, friend_id, course_id, node )
    #initial the flag

    node.each do |nd|
      #if the node has children
      if nd[ :node_items].is_a? (Array)
        @temp = count_learning_flag( user_id, friend_id, course_id, nd[ :node_items] )
      else
        @lesson_counter+=1

        #find out the learning history
        @history_user = UserLearningHistory.all( :conditions => { :user_id => user_id, :course_id => course_id, :lesson => nd[ :node_file] } )
        @history_other = UserLearningHistory.all( :conditions => { :user_id => friend_id, :course_id => course_id, :lesson => nd[ :node_file] } )

        #if the user has taken the course before
        if !@history_user.empty?
          @flag_user += 1
        end
        #if the target has taken the course before
        if !@history_other.empty?
          @flag_other += 1
        end
        #if the user and the target have taken the course together before
        if !@history_user.empty? && !@history_other.empty?
          @flag_together += 1
        end

      end
    end

    @return_value = { :lesson_counter => @lesson_counter, :flag_user => @flag_user, :flag_other => @flag_other, :flag_together => @flag_together }
    return @return_value
  end

  #get fb_information
  def get_fb_info( user_id )
    #update information and friend list
    @user = User.find(user_id)
    @authentication = Authentication.find_by_user_id( @user.id )
    @user.fb_id = @authentication.uid

    @friend_data = HTTParty.get('https://graph.facebook.com/' + @user.fb_id + '?fields=friends.fields(picture,email,name)&access_token=' + @authentication.token)
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
      @friends[index] = { :name => fd['name'], :uid => fd['id'], :friend_type => "0", :picture => fd['picture']['data']['url'] }

      #check the friend is close friend or not
      @close_friends.each do |cf|
        if fd['id'] == cf
          @friends[index] = { :name => fd['name'], :uid => fd['id'], :friend_type => "2", :picture => fd['picture']['data']['url'] }
        end
      end
      #check the friend is acquaintance or not
      @acquaintance_friends.each do |af|
        if fd['id'] == af
          @friends[index] = { :name => fd['name'], :uid => fd['id'], :friend_type => "1", :picture => fd['picture']['data']['url'] }
        end
      end
    end
    @user.friend = @friends 
    @user_data = HTTParty.get('https://graph.facebook.com/' + @user.fb_id + '?fields=picture,name' )
    @user.name = @user_data['name']
    @user.picture = @user_data['picture']['data']['url']
    @user.save
  end

end
