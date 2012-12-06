class AddFriendColumn < ActiveRecord::Migration
  def up
    add_column :users, :friend, :text
  end

  def down
  end
end
