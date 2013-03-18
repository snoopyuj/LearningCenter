class AddFbId < ActiveRecord::Migration
  def up
    add_column :users, :fb_id, :string
  end

  def down
  end
end
