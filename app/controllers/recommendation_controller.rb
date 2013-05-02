class RecommendationController < ApplicationController

  #friend_recommendation: homepage of friend_recommendation
  def friend_recommnedation
  end

  #friend_recommendation in specific course
  def friend_recommendation_in_course
    #find out the course that user choose
    @course  = Course.find( params[ :select_course] ) unless params[ :select_course].nil?
    #find out the current and his friends
    @user = User.find_by_email( current_user.email )
    @user_friend = @user.friend
    @users = User.all

    #find out the foreigners
    @user_friend.each do |usf|
      puts usf[ :uid]
      @users.delete_if{|us| us[ :fb_id] == usf[ :uid] }     
    end

    #store each friend's similarity in this course in an array
    @users_similarity = Array.new()
    @temp = Array.new()
    @index = 0
    @users.each do |us|
      @flag_user = 0
      @flag_other = 0
      @flag_together = 0
      @lesson_counter = 0

      #find out the target user
      @target = User.find_by_fb_id( us[ :uid] )
      next if @target.nil?

      #call calculate_learning_flag to calculate target's similarity in this course
      @temp = count_learning_flag( @user.id, @target.id, @course.id, @course.course_tree )
      @lesson_counter = @temp[ :lesson_counter].to_i
      @flag_user = @temp[ :flag_user].to_i
      @flag_other = @temp[ :flag_other].to_i
      @flag_together = @temp[ :flag_together].to_i

      #calculate the similarity
      if @flag_user > @flag_other
        @similarity = (@flag_together.to_f/@flag_user.to_f)
      else
        @similarity = (@flag_together.to_f/@flag_other.to_f)
      end

      #store the similartiy in the array
      @users_similarity[@index] = { :lesson_counter => @lesson_counter,
                                    :user_name => @user.email, :flag_user => @flag_user,
                                    :other_name => us[ :name ], :flag_other => @flag_other,
                                    :other_picture => us[ :picture], :other_id => us[ :fb_id],
                                    :flag_together => @flag_together, :pxy => @pxy,
                                    :similarity => @similarity.to_f }
      @index += 1
    end#users end
    #sort the result by the similarity value
    @result = @users_similarity.sort_by { |user| user[ :similarity] }.reverse
    #send the result back to the client side
    respond_to do |format|
      format.js 
      format.json { render :json => @result }
    end#respond end
  end#friend_recommendation_end

  #friend_recommendation in specific course category
  def friend_recommendation_in_category
    #find out the courses in the category that user chooses
    @courses = CategoryCourseRelationship.find( params[ :select_category] ).courses
    #find out the current and his friends
    @user = User.find_by_email( current_user.email )
    @user_friend = @user.friend
    @users = User.all

    #find out the foreigners
    @user_friend.each do |usf|
      puts usf[ :uid]
      @users.delete_if{|us| us[ :fb_id] == usf[ :uid] }
    end

    @result = Array.new()
    @courses.each do |course|
      #store each friend's similarity in this course in an array
      @users_similarity = Array.new()
      @temp = Array.new()
      @index = 0
      @users.each do |us|
        @flag_user = 0
        @flag_other = 0
        @flag_together = 0
        @lesson_counter = 0

        #find out the target user
        @target = User.find_by_fb_id( us[ :uid] )
        next if @target.nil?

        #call calculate_learning_flag to calculate target's similarity in this course
        @temp = count_learning_flag( @user.id, @target.id, course.id, course.course_tree )
        @lesson_counter = @temp[ :lesson_counter].to_i
        @flag_user = @temp[ :flag_user].to_i
        @flag_other = @temp[ :flag_other].to_i
        @flag_together = @temp[ :flag_together].to_i

        #calculate the similarity
        if @flag_user > @flag_other
          @similarity = (@flag_together.to_f/@flag_user.to_f)
        else
          @similarity = (@flag_together.to_f/@flag_other.to_f)
        end

        #store the similartiy in the array
        @users_similarity[@index] = { :lesson_counter => @lesson_counter,
                                     :user_name => @user.email, :flag_user => @flag_user,
                                     :other_name => us[ :name ], :flag_other => @flag_other,
                                     :other_picture => us[ :picture], :other_id => us[ :fb_id],
                                     :flag_together => @flag_together, :pxy => @pxy,
                                     :similarity => @similarity.to_f }
        @index += 1
      end#users end

      #accumulate the similarity of each course in this course category
      @users_similarity.each_with_index do |usimi, index|
        @temp = usimi[ :similarity].to_f
        if @result[index].nil?
          @result[index] = { :other_name => usimi[ :other_name], :other_picture => usimi[ :other_picture], :user_id => usimi[ :user_id],
                             :similarity => (@temp*@temp).to_f }
        else
          @temp1 = @result[index][ :similarity].to_f
          @result[index] = { :other_name => usimi[ :other_name], :other_picture => usimi[ :other_picture], :other_id => usimi[ :other_id],
                             :user_id => usimi[ :user_id],
                             :similarity => (@temp1.to_f + (@temp*@temp).to_f).to_f }
        end
      end     
    end#courses end

    #sort the result by the similarity value
    @result = @result.sort_by { |user| user[ :similarity] }.reverse
    #send the result back to the client side
    respond_to do |format|
      format.js
      format.json { render :json => @result }
    end#respond end

  end#friend_recommendation_in_category end

  #recommendationfriend to ask question in course
  def ask_recommendation_in_course
    puts "ask in course"
    #find out the course that user choose
    @course  = Course.find( params[ :select_course] ) unless params[ :select_course].nil?
    #find out the current and his friends
    @user = User.find_by_email( current_user.email )
    @users = @user.friend

    #store each friend's similarity in this course in an array
    @users_similarity = Array.new()
    @temp = Array.new()
    @index = 0
    @users.each do |us|
      @flag_user = 0
      @flag_other = 0
      @flag_together = 0
      @lesson_counter = 0

      #find out the target user
      @target = User.find_by_fb_id( us[ :uid] )
      next if @target.nil?

      #call calculate_learning_flag to calculate target's similarity in this course
      @temp = count_learning_flag( @user.id, @target.id, @course.id, @course.course_tree )
      @lesson_counter = @temp[ :lesson_counter].to_i
      @flag_user = @temp[ :flag_user].to_i
      @flag_other = @temp[ :flag_other].to_i
      @flag_together = @temp[ :flag_together].to_i

      #calculate the similarity
      if @flag_user > @flag_other
        @similarity = (@flag_together.to_f/@flag_user.to_f)
      else
        @similarity = (@flag_together.to_f/@flag_other.to_f)
      end

      #store the similartiy in the array
      @users_similarity[@index] = { :lesson_counter => @lesson_counter,
                                    :user_name => @user.email, :flag_user => @flag_user,
                                    :other_name => us[ :name ], :flag_other => @flag_other,
                                    :other_picture => us[ :picture], :other_id => us[ :uid],
                                    :flag_together => @flag_together, :pxy => @pxy,
                                    :similarity => @similarity.to_f }
      @index += 1
    end#users end

    #sort the result by the similarity value
    @result = @users_similarity.sort_by { |user| user[ :similarity] }.reverse
    #send the result back to the client side
    respond_to do |format|
      format.js
      format.json { render :json => @result }
    end#respond end

  end#ask_reommendation_in_course end

  #recommendation friend to ask question in category
  def ask_recommendation_in_category
    puts "ask in category"
    #find out the courses in the category that user chooses
    @courses = CategoryCourseRelationship.find( params[ :select_category] ).courses
    #find out the current and his friends
    @user = User.find_by_email( current_user.email )
    @users = @user.friend

    @result = Array.new()
    @courses.each do |course|
      #store each friend's similarity in this course in an array
      @users_similarity = Array.new()
      @temp = Array.new()
      @index = 0
      @users.each do |us|
        @flag_user = 0
        @flag_other = 0
        @flag_together = 0
        @lesson_counter = 0

        #find out the target user
        @target = User.find_by_fb_id( us[ :uid] )
        next if @target.nil?

        #call calculate_learning_flag to calculate target's similarity in this course
        @temp = count_learning_flag( @user.id, @target.id, course.id, course.course_tree )
        @lesson_counter = @temp[ :lesson_counter].to_i
        @flag_user = @temp[ :flag_user].to_i
        @flag_other = @temp[ :flag_other].to_i
        @flag_together = @temp[ :flag_together].to_i

        #calculate the similarity
        if @flag_user > @flag_other
          @similarity = (@flag_together.to_f/@flag_user.to_f)
        else
          @similarity = (@flag_together.to_f/@flag_other.to_f)
        end
 
        #store the similartiy in the array
        @users_similarity[@index] = { :lesson_counter => @lesson_counter,
                                     :user_name => @user.email, :flag_user => @flag_user,
                                     :other_name => us[ :name ], :flag_other => @flag_other,
                                     :other_picture => us[ :picture], :other_id => us[ :uid],
                                     :flag_together => @flag_together, :pxy => @pxy,
                                     :similarity => @similarity.to_f }
        @index += 1
      end#users end

      #accumulate the similarity of each course in this course category
      @users_similarity.each_with_index do |usimi, index|
        @temp = usimi[ :similarity].to_f
        if @result[index].nil?
          @result[index] = { :other_name => usimi[ :other_name], :other_picture => usimi[ :other_picture],
                             :similarity => (@temp*@temp).to_f }
        else
          @temp1 = @result[index][ :similarity].to_f
          @result[index] = { :other_name => usimi[ :other_name], :other_picture => usimi[ :other_picture], :other_id => usimi[ :other_id],
                             :similarity => (@temp1.to_f + (@temp*@temp).to_f).to_f }
        end
      end
    end#courses end

    #sort the result by the similarity value
    @result = @result.sort_by { |user| user[ :similarity] }.reverse
    #send the result back to the client side
    respond_to do |format|
      format.js
      format.json { render :json => @result }
    end#respond end

  end#ask_recommendation end

end #class end
