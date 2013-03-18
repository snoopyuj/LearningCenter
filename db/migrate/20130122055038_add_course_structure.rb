class AddCourseStructure < ActiveRecord::Migration
  def up
    add_column :courses, :course_tree, :string
  end

  def down
  end
end
