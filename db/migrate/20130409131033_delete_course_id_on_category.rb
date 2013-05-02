class DeleteCourseIdOnCategory < ActiveRecord::Migration
  def up
    remove_column :category_course_relationships, :course_id
  end

  def down
  end
end
