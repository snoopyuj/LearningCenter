class ChangeDataType < ActiveRecord::Migration
  def up
    remove_column :courses, :course_tree
  end

  def down
    add_column :courses, :course_tree, :text
  end
end
