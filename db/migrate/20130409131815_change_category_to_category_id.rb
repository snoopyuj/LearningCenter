class ChangeCategoryToCategoryId < ActiveRecord::Migration
  def up
    remove_column :courses, :category
    add_column :courses, :category_course_relationship_id, :integer
  end

  def down
  end
end
