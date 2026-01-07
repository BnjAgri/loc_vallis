class AddRoomUrlToRooms < ActiveRecord::Migration[7.1]
  def change
    add_column :rooms, :room_url, :text
  end
end
