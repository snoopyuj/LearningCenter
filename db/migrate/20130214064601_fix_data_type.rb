class FixDataType < ActiveRecord::Migration
  def up
    remove_column :courses, :course_tree
    add_column :courses, :course_tree, :string
  end

  def down
  end
end
