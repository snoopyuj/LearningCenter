class AddCourseTree < ActiveRecord::Migration
  def up
    add_column :courses, :course_tree, :text
  end

  def down
  end
end
