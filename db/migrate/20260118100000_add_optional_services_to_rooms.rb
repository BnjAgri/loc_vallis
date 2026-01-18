class AddOptionalServicesToRooms < ActiveRecord::Migration[7.1]
  def change
    add_column :rooms, :optional_services, :jsonb, null: false, default: []
  end
end
