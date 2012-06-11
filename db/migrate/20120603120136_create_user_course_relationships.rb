class CreateUserCourseRelationships < ActiveRecord::Migration
  def change
    create_table :user_course_relationships do |t|
      t.integer :user_id
      t.integer :course_id
      t.string :courseCurrent

      t.timestamps
    end
  end
end
