class CreateCategoryCourseRelationships < ActiveRecord::Migration
  def change
    create_table :category_course_relationships do |t|
      t.string :name
      t.integer :course_id
      t.timestamps
    end
  end
end
