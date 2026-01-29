class AddNotificationsLastSeenAtToUsersAndOwners < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :notifications_last_seen_at, :datetime
    add_index :users, :notifications_last_seen_at

    add_column :owners, :notifications_last_seen_at, :datetime
    add_index :owners, :notifications_last_seen_at
  end
end
