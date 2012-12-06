class AddToken < ActiveRecord::Migration
  def up
    add_column :authentications, :token, :string
  end

  def down
  end
end
