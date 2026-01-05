class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      t.references :room, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :status, null: false, default: "requested"
      t.integer :total_price_cents
      t.string :currency
      t.datetime :approved_at
      t.datetime :payment_expires_at
      t.string :stripe_checkout_session_id
      t.string :stripe_payment_intent_id
      t.string :stripe_refund_id
      t.datetime :refunded_at

      t.timestamps
    end

    add_index :bookings, :status
    add_index :bookings, [:room_id, :start_date, :end_date]
    add_index :bookings, :stripe_checkout_session_id, unique: true
    add_index :bookings, :stripe_payment_intent_id, unique: true
    add_index :bookings, :stripe_refund_id, unique: true
  end
end
