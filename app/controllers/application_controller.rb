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


      #if nd[ :node_items] == "none"
        #@lesson_counter += 1
        #puts @lesson_counter
        #@history_user = UserLearningHistory.all( :conditions => { :user_id => user_id, :course_id => course_id, :lesson => nd[ :node_file] } )
        #@history_other = UserLearningHistory.all( :conditions => { :user_id => friend_id, :course_id => course_id, :lesson => nd[ :node_file] } )

        #if the user has taken the course before
        #if !@history_user.empty?
          #@flag_user += 1
        #end
        #if the target has taken the course before
        #if !@history_other.empty?
          #@flag_other += 1
        #end
        #if the user and the target have taken the course together before
        #if !@history_user.empty? && !@history_other.empty?
          #@flag_together += 1
        #end
  
        #@return_value = { :lesson_counter => @lesson_counter, :flag_user => @flag_user, :flag_other => @flag_other, :flag_together => @flag_together }
        #return @return_value

      #if the node has no children
      #else
        #@temp_hash = Hash.new()
        #nd[ :node_items].each do |item|
          #@temp = count_learning_flag( user_id, friend_id, course_id, item, @temp_hash )
          #@lesson_counter += @temp[ :lesson_counter]
        #end
        #puts @temp
        #@flag_user += @temp[ :flag_user]
        #@flag_other += @temp[ :flag_other]
        #@flag_together += @temp[ :flag_together]
        #result = { :lesson_counter => @lesson_counter, :flag_user => @flag_user, :flag_other => @flag_other, :flag_together => @flag_together }
        #return result
      #end

      #result = { :lesson_counter => @lesson_counter, :flag_user => @flag_user, :flag_other => @flag_other, :flag_together => @flag_together }
      #return result
    #end
    #@lesson_counter += @temp[ :lesson_counter].to_i
    #@lesson_counter += @temp[ :lesson_counter].to_i
    #puts "lesson counter is " + @lesson_counter.to_s
    #result = { :lesson_counter => @lesson_counter, :flag_user => @flag_user, :flag_other => @flag_other, :flag_together => @flag_together }
    #return result
  end

end
