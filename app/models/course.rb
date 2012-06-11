class Course < ActiveRecord::Base
  has_many :user_course_relationships
  has_many :users, :through => :user_course_relationships
end
