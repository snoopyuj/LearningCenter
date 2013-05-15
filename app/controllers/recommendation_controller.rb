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
      @users.delete_if{|us| us[ :fb_id] == usf[ :uid] }     
    end
    #kick out myself
    @users.delete_if{ |us| us[ :fb_id] == @user.fb_id }

    #store each friend's similarity in this course in an array
    @users_similarity = Array.new()
    @index = 0
    @users.each do |us|
      @lesson_counter = 0
      @flag_user = 0
      @flag_other = 0
      @flag_together = 0

      #call count_learning_flag to calculate target's similarity in this course
      @temp = count_learning_flag( @user.id, us.id, @course.id, @course.course_tree )
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

      if @flag_user == 0 || @flag_other == 0
        @similarity = 0
      end

      #store the similartiy in the array
      @users_similarity[@index] = { :lesson_counter => @lesson_counter,
                                    :user_name => @user.email, :flag_user => @flag_user,
                                    :other_name => us[ :name], :flag_other => @flag_other,
                                    :other_picture => us[ :picture], :other_id => us[ :fb_id],
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
      @users.delete_if{|us| us[ :fb_id] == usf[ :uid] }
    end
    #kick out myself
    @users.delete_if{ |us| us[ :fb_id] == @user.fb_id }

    @temp_result = Array.new()
    @courses.each do |course|
      #store each friend's data in this course in an array
      @users_data = Array.new()
      @index = 0
      @users.each do |us|
        @lesson_counter = 0
        @flag_user = 0
        @flag_other = 0
        @flag_together = 0

        #call calculate_learning_flag
        @temp = count_learning_flag( @user.id, us.id, course.id, course.course_tree )
        @flag_user = (@temp[ :flag_user].to_f/@temp[ :lesson_counter].to_f).to_f
        @flag_other = (@temp[ :flag_other].to_f/@temp[ :lesson_counter].to_f).to_f

        @users_data[@index] = { :user_name => @user.email, :flag_user => (@flag_user**2).to_f,
                                :other_name => us[ :name], :flag_other => (@flag_other**2).to_f,
                                :other_picture => us[ :picture], :other_id => us[ :fb_id],
                                :flag_together => (@flag_user*@flag_other).to_f
                              }
        @index += 1
      end#users end

      #accumulate the data
      @users_data.each_with_index do |usdata, index|
        if @temp_result[index].nil?
          @temp_result[index] = usdata
        else
          @temp_flag_user = @temp_result[index][ :flag_user].to_f
          @temp_flag_other = @temp_result[index][ :flag_other].to_f
          @temp_flag_together = @temp_result[index][ :flag_together].to_f

          @temp_result[index] = { :user_name => @user.email, :flag_user => ( @temp_flag_user + usdata[ :flag_user].to_f ),
                                  :other_name => usdata[ :other_name ], :flag_other => ( @temp_flag_other + usdata[ :flag_other].to_f ),
                                  :other_picture => usdata[ :other_picture], :other_id => usdata[ :other_id],
                                  :flag_together => ( @temp_flag_together + usdata[ :flag_together].to_f )
                                }
        end
      end     
    end#courses end

    @result = Array.new()
    #calculate the similarity by Cosine Similarity
    @temp_result.each_with_index do |tr, index|
      if tr[ :flag_user].to_f == 0 || tr[ :flag_other].to_f == 0
        @similarity = 0
      else
        @similarity = ( tr[ :flag_together].to_f / ( Math.sqrt(tr[ :flag_user].to_f) * Math.sqrt(tr[ :flag_other].to_f) ).to_f ).to_f
      end

      @result[index] = { :other_name => tr[ :other_name], :other_picture => tr[ :other_picture], :other_id => tr[ :other_id],
                         :flag_user => tr[ :flag_user], :flag_other => tr[ :flag_other], :flag_together => tr[ :flag_together],
                         :similarity => @similarity.to_f }
    end

    #sort the result by the similarity value
    #@result = @result.sort_by { |user| user[ :similarity] }
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
      #find out the target user
      @target = User.find_by_fb_id( us[ :uid] )
      next if @target.nil?

      @lesson_counter = 0
      @flag_user = 0
      @flag_other = 0
      @flag_together = 0

      #call count_learning_flag to calculate target's similarity in this course
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

      if @flag_user == 0 || @flag_other == 0
        @similarity = 0
      end

      #store the similartiy in the array
      @users_similarity[@index] = { :lesson_counter => @lesson_counter,
                                    :user_name => @user.email, :flag_user => @flag_user,
                                    :other_name => us[ :name], :flag_other => @flag_other,
                                    :other_picture => us[ :picture], :other_id => us[ :uid],
                                    :flag_together => @flag_together, 
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

    @temp_result = Array.new()
    @courses.each do |course|
      #store each friend's similarity in this course in an array
      @users_data = Array.new()
      @temp = Array.new()
      @index = 0
      @users.each do |us|
        #find out the target user
        @target = User.find_by_fb_id( us[ :uid] )
        next if @target.nil?

        @lesson_counter = 0
        @flag_user = 0
        @flag_other = 0
        @flag_together = 0

        #call count_learning_flag
        @temp = count_learning_flag( @user.id, @target.id, course.id, course.course_tree )
        @flag_user = (@temp[ :flag_user].to_f/@temp[ :lesson_counter].to_f).to_f
        @flag_other = (@temp[ :flag_other].to_f/@temp[ :lesson_counter].to_f).to_f
 
        @users_data[@index] = { :user_name => @user.email, :flag_user => (@flag_user**2).to_f,
                                :other_name => us[ :name], :flag_other => (@flag_other**2).to_f,
                                :other_picture => us[ :picture], :other_id => us[ :uid],
                                :flag_together => (@flag_user*@flag_other).to_f
                              }

        @index += 1
      end#users end

      #accumulate the data
      @users_data.each_with_index do |usdata, index|
        if @temp_result[index].nil?
          @temp_result[index] = usdata
        else
          @temp_flag_user = @temp_result[index][ :flag_user].to_f
          @temp_flag_other = @temp_result[index][ :flag_other].to_f
          @temp_flag_together = @temp_result[index][ :flag_together].to_f

          @temp_result[index] = { :user_name => @user.email, :flag_user => ( @temp_flag_user + usdata[ :flag_user].to_f ),
                                  :other_name => usdata[ :other_name ], :flag_other => ( @temp_flag_other + usdata[ :flag_other].to_f ),
                                  :other_picture => usdata[ :other_picture], :other_id => usdata[ :other_id],
                                  :flag_together => ( @temp_flag_together + usdata[ :flag_together].to_f )
                                }
        end
      end
    end#courses end

    @result = Array.new()
    #calculate the similarity by Cosine Similarity
    @temp_result.each_with_index do |tr, index|
      if tr[ :flag_user].to_f == 0.0 || tr[ :flag_other].to_f == 0.0
        @similarity = 0
      else
        @similarity = ( tr[ :flag_together].to_f / ( Math.sqrt(tr[ :flag_user].to_f) * Math.sqrt(tr[ :flag_other].to_f) ).to_f ).to_f
      end

      @result[index] = { :other_name => tr[ :other_name], :other_picture => tr[ :other_picture], :other_id => tr[ :other_id],
                         :similarity => @similarity.to_f }
    end

    #sort the result by the similarity value
    @result = @result.sort_by { |user| user[ :similarity] }.reverse
    #send the result back to the client side
    respond_to do |format|
      format.js
      format.json { render :json => @result }
    end#respond end

  end#ask_recommendation end

  #course_recommendation: homepage of course recommendation
  def course_recommendation
  end

  #course_recommendation_calculation
  def course_recommendation_calculation
    #find out the courses in the category that user chooses
    @courses = CategoryCourseRelationship.find( params[ :select_category] ).courses
    @user = User.find_by_email( current_user.email )

    #*****STEP1: find out who is similar to me*****
    @users = User.all
    #kick out my self
    @users.delete_if{ |u| u.id == @user.id}

    @temp_result = Array.new()
    @courses.each do |course|
      #store each friend's similarity in this course in an array
      @users_data = Array.new()
      @temp = Array.new()
      @index = 0
      @users.each do |us|

        @lesson_counter = 0
        @flag_user = 0
        @flag_other = 0
        @flag_together = 0

        #call calculate_learning_flag
        @temp = count_learning_flag( @user.id, us.id, course.id, course.course_tree )
        @flag_user = (@temp[ :flag_user].to_f/@temp[ :lesson_counter].to_f).to_f
        @flag_other = (@temp[ :flag_other].to_f/@temp[ :lesson_counter].to_f).to_f

        @users_data[@index] = { :user_name => @user.email, :flag_user => (@flag_user**2).to_f,
                                :other_name => us[ :name], :flag_other => (@flag_other**2).to_f,
                                :other_picture => us[ :picture], :other_id => us[ :fb_id],
                                :flag_together => (@flag_user*@flag_other).to_f
                              }

        @index += 1
      end#users end

      #accumulate the data
      @users_data.each_with_index do |usdata, index|
        if @temp_result[index].nil?
          @temp_result[index] = usdata
        else
          @temp_flag_user = @temp_result[index][ :flag_user].to_f
          @temp_flag_other = @temp_result[index][ :flag_other].to_f
          @temp_flag_together = @temp_result[index][ :flag_together].to_f

          @temp_result[index] = { :user_name => @user.email, :flag_user => ( @temp_flag_user + usdata[ :flag_user].to_f ),
                                  :other_name => usdata[ :other_name ], :flag_other => ( @temp_flag_other + usdata[ :flag_other].to_f ),
                                  :other_picture => usdata[ :other_picture], :other_id => usdata[ :other_id],
                                  :flag_together => ( @temp_flag_together + usdata[ :flag_together].to_f )
                                }
        end
      end
    end#courses end

    @target_users = Array.new()
    #calculate the similarity by Cosine Similarity
    @temp_result.each_with_index do |tr, index|
      if tr[ :flag_user].to_f == 0 || tr[ :flag_other].to_f == 0
        @similarity = 0
      else
        @similarity = ( tr[ :flag_together].to_f / ( Math.sqrt(tr[ :flag_user].to_f) * Math.sqrt(tr[ :flag_other].to_f) ).to_f ).to_f
      end

      @target_users[index] = { :other_name => tr[ :other_name], :other_picture => tr[ :other_picture], :other_id => tr[ :other_id],
                               :similarity => @similarity.to_f }
    end

    #sort the result by the similarity value
    @target_users = @target_users.sort_by { |user| user[ :similarity] }.reverse
    #*****STEP1: find out who is similar to me*****

    #denominator of support: the number of data set of association rule
    @support_denominator = @target_users.length

    #*****STEP2: find out the course that the user is taken*****
    @course_finished = Array.new()
    @index = 0
    @courses.each do |c|
      @lesson_counter = 0
      @flag_user = 0
      check_learning_flag( @user.id, c.id, c.course_tree )
      @temp = ((@flag_user*2).to_f/@lesson_counter.to_f).to_f
      if @temp >= 0.3
         @course_finished[@index] = c
         @index += 1
      end
    end
    #*****STEP2: find out the course that the user is taken*****

    @rule_x = Array.new()
    @index = 0
    #*****STEP3: find out the STPE1 guys who have taken STEP2 courses*****
    @target_users.each do |tu|
      @target_user = User.find_by_fb_id(tu[ :other_id])

      @course_finished.each_with_index do |cf, index|
        @temp_result = Array.new()
  
        #if the learning path is over 0.3, we take this user finish this course
        @lesson_counter = 0
        @flag_user = 0
        check_learning_flag( @target_user.id, cf.id, cf.course_tree )
        @temp = ((@flag_user*2).to_f/@lesson_counter.to_f).to_f
        if @temp >= 0.3
          @temp_result[index] = 1
        else
          @temp_result[index] = 0
        end
      end
      @rule_x[@index] = { :name => @target_user.name, :fb_id => @target_user.fb_id, :result => @temp_result }
      @index += 1
    end

    #if there is any course in course_finished is not taken by the user in target_users, delete him!
    #so the remain users are the guys in STEP1 who have taken STEP courses
    @rule_x.delete_if{ |tus| tus[ :result].include?(0) }
    #*****STEP3: find out the STPE1 guys who have taken STEP2 courses*****

    #denominator of confedence: the number of X, where X > Y
    @confedence_denominator = @rule_x.length

    #*****STEP4: use association rule to find out the remain courses taken probability*****
    #find out the remain courses
    @course_unfinish = @courses - @course_finished        
    @rule_y = Array.new( @course_unfinish.length )
    @course_unfinish.each_with_index do |cuf, index|
      @rule_y[index] = { :courseID => cuf.id, :courseName => cuf.courseName, :ar_count => 0.0 }
      @rule_x.each do |rx|
        @temp_user = User.find_by_fb_id(rx[ :fb_id])

        #check the user is the current user's friend or not
        @check_friend = 0.0
        @user.friend.each do |uf|
          if @temp_user.fb_id == uf[ :uid]
            @check_friend = (uf[ :friend_type].to_f/10.0).to_f
          end
        end

        #if the learning path is over 0.3, we take this user finish this course
        @lesson_counter = 0
        @flag_user = 0
        check_learning_flag( @temp_user.id, cuf.id, cuf.course_tree )
        @temp = ((@flag_user*2).to_f/@lesson_counter.to_f).to_f
        if @temp >= 0.3
          #if the user has finish the course
          @rule_y[index][ :ar_count] += 1.0
          #friend weight
          @rule_y[index][ :ar_count] += @check_friend.to_f
        end
      end
    end
    #*****STEP4: use association rule to find out the remain courses taken probability*****

    #*****STEP5: calculate the support and confedence*****
    @result = Array.new() 
    @rule_y.each_with_index do |ry, index|
      @course = Course.find_by_courseID( ry[ :courseID] )
      @result[index] = { :corseID => @course.id, :courseName => @course.courseName, 
                         :support => (ry[ :ar_count].to_f/@support_denominator.to_f).to_f,
                         :confedence => (ry[ :ar_count].to_f/@confedence_denominator.to_f).to_f
                       }
    end
    @result = @result.sort_by{ |r| r[ :confedence] }.reverse
    #*****STEP5: calculate the support and confedence*****
    respond_to do |format|
      format.js
      format.json { render :json => @result }
    end#respond end

  end#course_recommendation_calculation end
end #class end
