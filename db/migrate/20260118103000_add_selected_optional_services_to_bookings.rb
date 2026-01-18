class AddSelectedOptionalServicesToBookings < ActiveRecord::Migration[7.1]
  def change
    add_column :bookings, :selected_optional_services, :jsonb, null: false, default: []
  end
end
