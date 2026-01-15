class AddContactFieldsToOwners < ActiveRecord::Migration[7.1]
  def change
    add_column :owners, :guesthouse_name, :string
    add_column :owners, :postal_address, :text
    add_column :owners, :phone, :string
  end
end
