class AddLastReadAtToBookings < ActiveRecord::Migration[7.1]
  def change
    add_column :bookings, :owner_last_read_at, :datetime
    add_column :bookings, :user_last_read_at, :datetime

    add_index :bookings, :owner_last_read_at
    add_index :bookings, :user_last_read_at
  end
end
