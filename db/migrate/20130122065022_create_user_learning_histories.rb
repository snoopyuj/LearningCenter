class CreateUserLearningHistories < ActiveRecord::Migration
  def change
    create_table :user_learning_histories do |t|
      t.integer :user_id
      t.integer :course_id
      t.string :lesson

      t.timestamps
    end
  end
end
