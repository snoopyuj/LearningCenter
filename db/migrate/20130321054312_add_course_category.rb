class AddCourseCategory < ActiveRecord::Migration
  def up
    add_column :courses, :category, :string
  end

  def down
  end
end
