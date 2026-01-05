class CreateRooms < ActiveRecord::Migration[7.1]
  def change
    create_table :rooms do |t|
      t.references :owner, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :capacity

      t.timestamps
    end
  end
end
