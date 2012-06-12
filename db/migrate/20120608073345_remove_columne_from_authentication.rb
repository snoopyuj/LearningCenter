class RemoveColumneFromAuthentication < ActiveRecord::Migration
  def up
    remove_column :authentications, :index, :create, :destroy
  end

  def down
  end
end
