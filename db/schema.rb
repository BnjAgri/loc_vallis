# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_02_06_090000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "articles", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.string "image_url"
    t.bigint "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_articles_on_owner_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.bigint "user_id", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.string "status", default: "requested", null: false
    t.integer "total_price_cents"
    t.string "currency"
    t.datetime "approved_at"
    t.datetime "payment_expires_at"
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.string "stripe_refund_id"
    t.datetime "refunded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "owner_last_read_at"
    t.datetime "user_last_read_at"
    t.jsonb "selected_optional_services", default: [], null: false
    t.datetime "status_changed_at"
    t.datetime "review_request_sent_at"
    t.index ["owner_last_read_at"], name: "index_bookings_on_owner_last_read_at"
    t.index ["review_request_sent_at"], name: "index_bookings_on_review_request_sent_at"
    t.index ["room_id", "start_date", "end_date"], name: "index_bookings_on_room_id_and_start_date_and_end_date"
    t.index ["room_id"], name: "index_bookings_on_room_id"
    t.index ["status"], name: "index_bookings_on_status"
    t.index ["status_changed_at"], name: "index_bookings_on_status_changed_at"
    t.index ["stripe_checkout_session_id"], name: "index_bookings_on_stripe_checkout_session_id", unique: true
    t.index ["stripe_payment_intent_id"], name: "index_bookings_on_stripe_payment_intent_id", unique: true
    t.index ["stripe_refund_id"], name: "index_bookings_on_stripe_refund_id", unique: true
    t.index ["user_id"], name: "index_bookings_on_user_id"
    t.index ["user_last_read_at"], name: "index_bookings_on_user_last_read_at"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.string "sender_type", null: false
    t.bigint "sender_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id", "created_at"], name: "index_messages_on_booking_id_and_created_at"
    t.index ["booking_id"], name: "index_messages_on_booking_id"
    t.index ["sender_type", "sender_id"], name: "index_messages_on_sender"
  end

  create_table "opening_periods", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "nightly_price_cents", null: false
    t.string "currency", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id", "start_date", "end_date"], name: "index_opening_periods_on_room_id_and_start_date_and_end_date"
    t.index ["room_id"], name: "index_opening_periods_on_room_id"
  end

  create_table "owners", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "guesthouse_name"
    t.text "postal_address"
    t.string "phone"
    t.datetime "notifications_last_seen_at"
    t.index ["email"], name: "index_owners_on_email", unique: true
    t.index ["notifications_last_seen_at"], name: "index_owners_on_notifications_last_seen_at"
    t.index ["reset_password_token"], name: "index_owners_on_reset_password_token", unique: true
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "rating", null: false
    t.text "comment", null: false
    t.bigint "booking_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_reviews_on_booking_id", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.bigint "owner_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "room_url"
    t.jsonb "optional_services", default: [], null: false
    t.index ["owner_id"], name: "index_rooms_on_owner_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "postal_address"
    t.string "phone"
    t.string "first_name"
    t.string "last_name"
    t.datetime "notifications_last_seen_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["notifications_last_seen_at"], name: "index_users_on_notifications_last_seen_at"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "articles", "owners"
  add_foreign_key "bookings", "rooms"
  add_foreign_key "bookings", "users"
  add_foreign_key "messages", "bookings"
  add_foreign_key "opening_periods", "rooms"
  add_foreign_key "reviews", "bookings"
  add_foreign_key "reviews", "users"
  add_foreign_key "rooms", "owners"
end
