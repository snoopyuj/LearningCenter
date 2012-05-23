class CoursesController < ApplicationController

    #before_filter :authenticate_user!
    
    #method index: list the courses
    def index
        @courses = Course.all
    end
    
    #method show: show the specific course
    def info
        @course = Course.find(params[ :id])
    end

    #method download_course_list
    def download_course_list
        ActiveRecord::Base.include_root_in_json = true

        @courses = Course.all
        @course_list = Array.new([1...@courses.length])

        # find the course object and store the attributes in the course_list array
        # each cell of the course_list array represents a course
        for i in 0...@courses.length
            @course = Course.find(i+1)
            @course_list[i] =  { :courseID => @course.courseID, :courseName => @course.courseName, :courseStatus => @course.courseStatus, :courseURL => @course.courseURL, :courseCurrent => @course.courseCurrent }
        end

        #make a json object with the course_list array
        @json_object = ActiveSupport::JSON.encode( { :userID => "12345", :coursesList => @course_list} )

        #method send_data: send a streaming data to client, and :disposition determines the type of file(attachment file or inline file)
        send_data @json_object, :type => "application/json", :disposition => "inline"
    end

    #method upload_course_list
    def upload_course_list
        @parsed_json["userID"]["coursesList"] = ActiveSuppot::JSON.decode( :course_list)

        @parsed_json["coursesList"].each do |courseID, courseCurrent|
            @course = Course.find( :courseID => courseID)
            @course.courseCurrent = courseCurrent
            @course.save
        end
    end

    def after_sign_in_path_for(resource)
      redirect_to "140.115.53.92/courses"
      #redirect_to :controller => :course, :action => :index
    end

    def after_sign_out_path_for(resource)
      redirect_to "140.115.53.92/courses"
    end

end
