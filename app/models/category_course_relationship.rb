class CategoryCourseRelationship < ActiveRecord::Base
  has_many :courses
end
