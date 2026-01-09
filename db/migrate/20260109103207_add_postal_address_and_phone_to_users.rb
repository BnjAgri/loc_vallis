class AddPostalAddressAndPhoneToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :postal_address, :text
    add_column :users, :phone, :string
  end
end
