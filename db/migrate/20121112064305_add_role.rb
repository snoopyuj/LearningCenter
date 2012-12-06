class AddRole < ActiveRecord::Migration
  def up
    add_column :users, :role, :integer
  end

  def down
  end
end
