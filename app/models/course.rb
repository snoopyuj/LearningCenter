class Course < ActiveRecord::Base
  has_many :user_course_relationships
  has_many :users, :through => :user_course_relationships

  has_many :user_learning_histories
  has_many :users, :through => :user_learning_histories


  serialize :course_tree, Array #store course structure in an array
end
