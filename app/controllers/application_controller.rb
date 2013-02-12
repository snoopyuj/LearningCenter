class ApplicationController < ActionController::Base
  protect_from_forgery

  #parse the current node
  def parse_node( node )

    @check = node.css('/item')
    #if the inpput node has no children, @array_check.nil = true
    if @check.empty?
      puts "not array"
      @return_value = { :title => node.css('/title').text, :identifierref => node['identifierref'] }
      return @return_value

    #if the input node has children, @array_check.nil = false
    else
      puts "array"
      #parse the input first
      @children = node.css('/item')
      #use an array to store the children
      @temp_array = Array.new()
      @list_array = Array.new()
      @index = 0
      #finish_flag: check out if all the children are parsed or not
      @finish_flag == false
      #handle each children
      @children.each_with_index do |c, i|
        #parse the child
        @temp = parse_node(c)
        #store the parsed child's result
        #if the return @temp is an array, it means that all the children are parsed, so store the array
        if @temp.is_a? (Array)
          puts "  list"
          @list_array[@index] = { :title => c.css('/title').text, :list => @temp }
          @index += 1
          @finish_flag = true
        #if the return @temp is not an array, it means that it is the leaf, so store the value
        else
          puts "  temp"
          @temp_array[i] = { :title => @temp[ :title], :identifierref => @temp[ :identifierref] }
        end
      end

      @return_value = Array.new()      
      if @finish_flag == true
        @return_value = @list_array 
      else
        @return_value = @temp_array
      end

      return @return_value
    end
  end

  #get_learning_history
  def get_learning_history(user_id, course_id)

    @learning_history = @course.course_tree
    @learning_history.each do |h|
      #if this node has no child
      if h[ :lesson_tree].empty?
        @history = UserLearningHistory.all( :conditions => { :user_id => user_id, :course_id => course_id, :lesson => h[ :lesson_file] } )

        #check out the learning history
        @read_flag = false
        if @history.empty?
          @read_flag = false
        else
          @read_flag = true
        end

        h[ :read_flag] = @read_flag
        #if this node has children
        else
          @lesson_tree = h[ :lesson_tree]
          @lesson_tree.each_with_index do | t, index|
            @history = UserLearningHistory.all( :conditions => { :user_id => user_id, :course_id => course_id, :lesson => t[ :lesson_file] } )
            puts @history
            #check out the learning history
            @read_flag = false
            if @history.empty?
              @read_flag = false
            else
              @read_flag = true
            end

            h[ :lesson_tree][index][ :read_flag] = @read_flag
          end
        end
      end
      
      return @learning_history
    end

end
