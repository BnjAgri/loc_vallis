class AddFirstNameLastNameToUsersAndOwners < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string

    add_column :owners, :first_name, :string
    add_column :owners, :last_name, :string
  end
end
