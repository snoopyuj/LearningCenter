class CoursesController < ApplicationController

    #before_filter :authenticate_user!
    
    #method index: list the courses
    def index
      @courses = Course.all

      if current_user
        @user = User.find_by_email(current_user.email)    
      end
    end
    
    #method show: show the specific course
    def info
        @course = Course.find(params[ :id]) #find out the course
        @user_id = current_user.id #find out the current user

        #find out the courseCurrent of the course of the current user
        @temp = UserCourseRelationship.all( :conditions => { :user_id => @user_id, :course_id => @course.id})

        if @temp.empty?
          @courseCurrent = "none"
        else
          @courseCurrent = @temp[0]["courseCurrent"]
        end
    end

    #method parse_lesson_list: parse the activity tree of the course
    def parse_lesson_tree
      require 'open-uri'
      #find out the course tree

      #find out the imsmanifest file and parse the organization/item part
      @course = Course.find( params[ :id] )
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
            @course_tree[i] = { :module_name => m.css('/title').text, :lesson_tree => @lesson_tree, :lesson_file => @file }
          end
        #if there is child under the item
        else
          @lessons.each_with_index do |l, j|
            @temp = l.css('/title')
            @resources.each do |r|
              if r['identifier'] == l['identifierref']
                @file = r['href']
              end
              @lesson_tree[j] = { :lesson_name => @temp.text, :lesson_file => @file }
            end
          end
          @course_tree[i] = { :module_name => m.css('/title').text, :lesson_tree => @lesson_tree }
        end
      end
      @course.course_tree = @course_tree
      @course.save
      @json_object = ActiveSupport::JSON.encode( { :courseID => @course.courseID, :courseName => @course.courseName, :courseStatus => @course.courseStatus, 
                                                   :courseURL => @course.courseURL, :courseTree => @course_tree } )
      render :json => @json_object
      #send_data @json_object, :type => "application/json", :disposition => "inline"
    end

    #test for recursive way
    def parse_lesson_tree_test
      require 'open-uri'
      #find out the course tree

      #find out the imsmanifest file and parse the organization/item part
      @course = Course.find( params[ :id] )
      @uri = @course.courseURL + "imsmanifest.xml"
      @imsmanifest = open(@uri).read
      @doc = Nokogiri::XML(@imsmanifest)
      @modules = @doc.css('//organizations/organization/item')
      @resources = @doc.css('//resources/resource')

      @course_tree = Array.new()
      #store the parsed data in to an array
      @modules.each_with_index do |m, index|
        @course_tree[index] = parse_node( m )
      end
      render :json => @course_tree
      #@json_object = ActiveSupport::JSON.encode( { :courseID => @course.courseID, :courseName => @course.courseName, :courseStatus => @course.courseStatus,
      #                                             :courseURL => @course.courseURL, :courseTree => @course_tree } )
      #send_data @json_object, :type => "application/json", :disposition => "inline"
    end


    #method download_course_list
    def download_course_list
        ActiveRecord::Base.include_root_in_json = true

        @courses = Course.all
        @course_list = Array.new(@courses.length)
        
        # find the course object and store the attributes in the course_list array
        # each cell of the course_list array represents a course
        for i in 0...(@courses.length)
            @course = Course.find(i+1)
            @temp = UserCourseRelationship.all( :conditions => { :user_id => current_user.id, :course_id => @course.id})
             
            if @temp.empty?
              @courseCurrent = "none"
            else
              @courseCurrent = @temp[0]["courseCurrent"]
            end

            @course_list[i] =  { :courseID => @course.courseID, :courseName => @course.courseName, :courseStatus => @course.courseStatus, :courseURL => @course.courseURL, :courseCurrent => @courseCurrent }
        end

        #make a json object with the course_list array
        @json_object = ActiveSupport::JSON.encode( { :userID => current_user.email, :coursesList => @course_list} )

        #method send_data: send a streaming data to client, and :disposition determines the type of file(attachment file or inline file)
        send_data @json_object, :type => "application/json", :disposition => "inline"
    end

    #method upload_course_list
    def upload_course_list
        #parse the parameter into json object
        @temp =  params[ :course_list]
        @parsed = ActiveSupport::JSON.decode( @temp )   
        @user_id = User.find_by_email( @parsed["userID"]).id
        

        #use find_by_courseID to find the course and update the attribute
        for i in 0...@parsed["coursesList"].length
            @relation = UserCourseRelationship.find_by_user_id_and_course_id( @user_id, @parsed["coursesList"][i]["courseID"] )
            @relation.update_attribute( :courseCurrent, @parsed["coursesList"][i]["courseCurrent"] )
        end
        redirect_to courses_path
    end

    #method parsed_resource: find out the imsmanifest.xml file
    def view_course

      require 'open-uri'

      #find out the current course
      @course = Course.find(params[ :id])
      @user_id = User.find_by_email(current_user.email).id
      @temp = UserCourseRelationship.find_by_user_id_and_course_id( @user_id, params[ :id] )

      if @temp.nil?
        @temp = UserCourseRelationship.new( :user_id => @user_id, :course_id => params[ :id], :courseCurrent => "none")
      end

      #find out the imsmanifest file of the course
      @uri = @course.courseURL + "imsmanifest.xml"
      @imsmanifest = open(@uri).read
      @doc = Nokogiri::XML(@imsmanifest)
      @resources = @doc.css('//resources/resource')

      #read_flag: to check the user is first time opening the course today or not
      @read_flag = params[ :first]

      #if it is the first time today
      if @read_flag == "1" then
        @index = "0"
        #the user has comming once~
        if @temp.courseCurrent != "none" then
          @resources.each_with_index do |r, index|
            if r['href'] == @temp.courseCurrent then
              @index = index.to_s
            end
          end
        end
      end
      #if it is not the first time today, it means the user is reading the course now
      #so to handle next/previous page or suspend
      if @read_flag == "0" then
        #index: the index of the current page in the resources array
        @index = params[ :index]
        #go: command of next/previous page
        @go = params[ :go]

        #params[ :go] == 1 means go next page
        if @go == "1" then
          #if user click next page, then it will record the learning history
          @history = UserLearningHistory.find_by_user_id_and_course_id_and_lesson( @user_id, params[ :id], @resources[@index.to_i]['href'].to_s  )
          if @history.nil?
            @new_history = UserLearningHistory.new( :user_id => @user_id, :course_id => params[ :id], :lesson => @resources[@index.to_i]['href'].to_s )
            @new_history.save
          end
          @index = (@index.to_i + 1).to_s
        end
        #params[ :go] == -1 means go previous page
        if @go == "-1" then
          @index = (@index.to_i - 1).to_s
        end
        #params[ :go] == 0 means suspend
        if @go == "0" then
          @temp.courseCurrent = @resources[@index.to_i]['href'].to_s
          @temp.save

          redirect_to courses_path
        end
      end
    end

    #get_learning_history
    def learning_history
      @users = User.all
      @user = User.find_by_email( current_user.email )
      @course_tree = Course.find( params[ :id] ).course_tree

      #check out each user's similarity in this course
      @users_similarity = Array.new()
      @users.each_with_index do |us, index|
        #flag to calculate the learning history
        @flag_user = 0
        @flag_other = 0
        @flag_together = 0
        @lesson_counter = 0

        @course_tree.each do |ct|
          if ct[ :lesson_tree].is_a? Array
            ct[ :lesson_tree].each do |lt|
              @lesson_counter += 1

              @history_user = UserLearningHistory.all( :conditions => { :user_id => @user.id, :course_id => params[ :id], :lesson => lt[ :lesson_file] } )
              @history_other = UserLearningHistory.all( :conditions => { :user_id => us.id, :course_id => params[ :id], :lesson => lt[ :lesson_file] } )

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
          
          else
            @lesson_counter += 1

            @history_user = UserLearningHistory.all( :conditions => { :user_id => @user.id, :course_id => params[ :id], :lesson => ct[ :lesson_file] } )
            @history_other = UserLearningHistory.all( :conditions => { :user_id => us.id, :course_id => params[ :id], :lesson => ct[ :lesson_file] } )

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
        #calculate the similarity
        @pxy = ( @flag_together.to_f/@lesson_counter.to_f )
        @px = ( @flag_user.to_f/@lesson_counter.to_f )
        @py = ( @flag_other.to_f/@lesson_counter.to_f )

        if @px != 0 && @py != 0
          @mi = @pxy*Math::log( ( @pxy/(@px*@py) ), 10)
        else
          @mi = 0
        end
        #store the similartiy in the array
        @users_similarity[index] = { :lesson_counter => @lesson_counter, 
                                     :user_name => @user.email, :flag_user => @flag_user, :px => @px,
                                     :other_name => us.email, :flag_other => @flag_other, :py => @py,
                                     :flag_together => @flag_together, :pxy => @pxy,
                                     :similarity => @mi }
      end
      render :json => @users_similarity
    end

    #progress_monitor: let teacher get learning of all students
    def progress_monitor_by_course

      @courses = Course.all
      @users =  User.all
      @relations = UserCourseRelationship.all 
    end

    #progress_monitor: let teacher get learning of all students
    def progress_monitor_by_user

      @user = User.find_by_email(params[ :search])
      @courses = Course.all
      @relations = UserCourseRelationship.all  
    end


    #method after_sign_in_for: override the method in devise
    def after_sign_in_path_for(resource)
      redirect_to courses_path
      #redirect_to :controller => :course, :action => :index
    end

    #method after_sign_out_for: override the method in devise
    def after_sign_out_path_for(resource)
      redirect_to courses_path
    end

end
