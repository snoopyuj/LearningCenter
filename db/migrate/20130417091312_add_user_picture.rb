class AddUserPicture < ActiveRecord::Migration
  def up
    add_column :users, :picture, :string
  end

  def down
  end
end
