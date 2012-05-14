class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.integer :courseID
      t.string :courseName
      t.integer :courseStatus
      t.text :courseURL
      t.string :courseCurrent

      t.timestamps
    end
  end
end
