class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :sender, polymorphic: true, null: false
      t.text :body, null: false

      t.timestamps
    end
    add_index :messages, [:booking_id, :created_at]
  end
end
