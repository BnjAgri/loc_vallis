class CreateOpeningPeriods < ActiveRecord::Migration[7.1]
  def change
    create_table :opening_periods do |t|
      t.references :room, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :nightly_price_cents, null: false
      t.string :currency, null: false

      t.timestamps
    end

    add_index :opening_periods, [:room_id, :start_date, :end_date]
  end
end
