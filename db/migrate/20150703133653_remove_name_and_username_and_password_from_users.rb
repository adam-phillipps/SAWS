class RemoveNameAndUsernameAndPasswordFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :name, :string
    remove_column :users, :username, :string
    remove_column :users, :password, :string
  end
end
