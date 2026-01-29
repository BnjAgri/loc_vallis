class AddStatusChangedAtToBookings < ActiveRecord::Migration[7.1]
  def up
    add_column :bookings, :status_changed_at, :datetime
    add_index :bookings, :status_changed_at

    # Backfill to keep semantics predictable for existing rows.
    execute("UPDATE bookings SET status_changed_at = updated_at WHERE status_changed_at IS NULL")
  end

  def down
    remove_index :bookings, :status_changed_at
    remove_column :bookings, :status_changed_at
  end
end
