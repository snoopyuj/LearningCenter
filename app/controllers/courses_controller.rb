class CoursesController < ApplicationController

    #before_filter :authenticate_user!
    
    #method index: list the courses
    def index
        @courses = Course.all
    end
    
    #method show: show the specific course
    def info
        @course = Course.find(params[ :id]) #find out the course
        @user_id = current_user.id #find out the current user

        #find out the courseCurrent of the course of the current user
        @temp = UserCourseRelationship.all( :conditions => { :user_id => @user_id, :course_id => @course.courseID})
        @courseCurrent = @temp[0]["courseCurrent"]
    end

    #method download_course_list
    def download_course_list
        ActiveRecord::Base.include_root_in_json = true

        @courses = Course.all
        @course_list = Array.new([1...@courses.length])

        @user_id = current_user.id #find out the current user
        
        # find the course object and store the attributes in the course_list array
        # each cell of the course_list array represents a course
        for i in 0...@courses.length
            @course = Course.find(i+1)
            @temp = UserCourseRelationship.all( :conditions => { :user_id => @user_id, :course_id => @course.courseID})
            @courseCurrent = @temp[0]["courseCurrent"]

            @course_list[i] =  { :courseID => @course.courseID, :courseName => @course.courseName, :courseStatus => @course.courseStatus, :courseURL => @course.courseURL, :courseCurrent => @courseCurrent }
        end

        #make a json object with the course_list array
        @json_object = ActiveSupport::JSON.encode( { :userID => "12345", :coursesList => @course_list} )

        #method send_data: send a streaming data to client, and :disposition determines the type of file(attachment file or inline file)
        send_data @json_object, :type => "application/json", :disposition => "inline"
    end

    #method upload_course_list
    def upload_course_list
        #@temp = :course_list
        #parse the parameter into json object
        @parsed = ActiveSuppot::JSON.decode( params[ :course_list]["upload"] )

        @course = Course.find_by_courseID(1)
        @course.update_attribute( :courseCurrent, @parsed["coursesList"][0]["courseCurrent"])
        @course.save
            
        #use find_by_courseID to find the course and update the attribute
        #for i in 0...@parsed["coursesList"].length
            #@course = Course.find_by_courseID( @parsed["coursesList"][i]["courseID"] )
            #@course.update_attribute( :courseCurrent, @parsed["coursesList"][i]["courseCurrent"] )
            #@course.save
        #end
    end

    #method after_sign_in_for: override the method in devise
    def after_sign_in_path_for(resource)
      redirect_to "140.115.53.92/courses"
      #redirect_to :controller => :course, :action => :index
    end

    #method after_sign_out_for: override the method in devise
    def after_sign_out_path_for(resource)
      redirect_to "140.115.53.92/courses"
    end

end
