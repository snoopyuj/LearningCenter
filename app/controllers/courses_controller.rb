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
        @temp = UserCourseRelationship.all( :conditions => { :user_id => @user_id, :course_id => @course.courseID})

        if @temp.empty?
          @courseCurrent = "none"
        else
          @courseCurrent = @temp[0]["courseCurrent"]
        end
    end

    #method download_course_list
    def download_course_list
        ActiveRecord::Base.include_root_in_json = true

        @courses = Course.all
        @course_list = Array.new([1...@courses.length])
        
        # find the course object and store the attributes in the course_list array
        # each cell of the course_list array represents a course
        for i in 0...(@courses.length-1)
            @course = Course.find(i+1)
            @temp = UserCourseRelationship.all( :conditions => { :user_id => current_user.id, :course_id => @course.courseID})
             
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
      @temp = UserCourseRelationship.find_by_user_id_and_course_id( @user_id, params[ :id])

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
