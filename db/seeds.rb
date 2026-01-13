# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require "securerandom"
require "faker"
require "net/http"
require "uri"
require "json"

puts "Seeding…"
if Rails.env.development?
  PASSWORD = "password123".freeze
  TOTO_PASSWORD = "toto".freeze
  CURRENCY = "EUR".freeze

  FALLBACK_ROOM_IMAGE_URL = "https://raw.githubusercontent.com/lewagon/fullstack-images/master/uikit/breakfast.jpg".freeze
  ROOM_IMAGE_URLS = [
    "https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1600&q=80",
    "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1600&q=80",
    "https://images.unsplash.com/photo-1551887373-6a6d5e5d2f2f?auto=format&fit=crop&w=1600&q=80",
    "https://images.unsplash.com/photo-1560448070-c26f9bba7ed5?auto=format&fit=crop&w=1600&q=80",
    "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1600&q=80",
    "https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?auto=format&fit=crop&w=1600&q=80"
  ].freeze

  def seeded_room_image_url
    ROOM_IMAGE_URLS.sample || FALLBACK_ROOM_IMAGE_URL
  end

  def fake_stripe_ids
    {
      stripe_checkout_session_id: "cs_test_#{SecureRandom.hex(10)}",
      stripe_payment_intent_id: "pi_test_#{SecureRandom.hex(10)}"
    }
  end

  def create_booking!(room:, user:, start_date:, nights:)
    Booking.create!(
      room:,
      user:,
      start_date:,
      end_date: start_date + nights
    )
  end

  today = Date.current

  puts "Cleaning existing data (development only)…"
  Message.delete_all
  Review.delete_all
  Booking.delete_all
  OpeningPeriod.delete_all
  Room.delete_all
  User.delete_all
  Owner.delete_all

  owner = Owner.create!(email: "owner@toto.com", password: TOTO_PASSWORD, password_confirmation: TOTO_PASSWORD)
  puts "Owner (fixed): #{owner.email} / #{TOTO_PASSWORD}"

  users = []
  fixed_user = User.create!(email: "user@toto.com", password: TOTO_PASSWORD, password_confirmation: TOTO_PASSWORD)
  users << fixed_user

  (1..7).each do |i|
    users << User.create!(
      email: "user#{i}@locvallis.test",
      password: PASSWORD,
      password_confirmation: PASSWORD
    )
  end

  puts "Users: #{users.size} created"
  puts "User (fixed): #{fixed_user.email} / #{TOTO_PASSWORD}"
  puts "User sample: #{users[1].email} / #{PASSWORD}"

  rooms = []
  2.times do |i|
    rooms << Room.create!(
      owner:,
      name: "Chambre #{i + 1}",
      description: Faker::Lorem.paragraph(sentence_count: 2),
      capacity: [1, 2, 3, 4].sample,
      room_url: seeded_room_image_url
    )
  end
  puts "Rooms: #{rooms.size} created"

  rooms.each do |room|
    OpeningPeriod.create!(
      room:,
      start_date: today - 200,
      end_date: today + 200,
      nightly_price_cents: rand(8_000..18_000),
      currency: CURRENCY
    )
  end
  puts "Opening periods: #{OpeningPeriod.count}"

  bookings = []

  rooms.each do |room|
    # 1) requested (future)
    bookings << create_booking!(room:, user: users.sample, start_date: today + 10, nights: 3)

    # 2) approved_pending_payment (future)
    b2 = create_booking!(room:, user: users.sample, start_date: today + 20, nights: 2)
    b2.approve!(by: owner)
    bookings << b2

    # 3) confirmed_paid (past) -> review eligible
    b3 = create_booking!(room:, user: users.sample, start_date: today - 30, nights: 4)
    b3.approve!(by: owner)
    b3.update!(status: "confirmed_paid", **fake_stripe_ids)
    bookings << b3

    # 4) refunded (past) -> review eligible
    b4 = create_booking!(room:, user: users.sample, start_date: today - 20, nights: 2)
    b4.approve!(by: owner)
    b4.update!(status: "confirmed_paid", **fake_stripe_ids)
    b4.mark_refunded!(refund_id: "re_test_#{SecureRandom.hex(10)}")
    bookings << b4
  end

  puts "Bookings: #{bookings.size} created"

  bookings.each_with_index do |booking, idx|
    Message.create!(
      booking:,
      sender: booking.user,
      body: Faker::Lorem.sentence(word_count: 10),
      created_at: (3.days.ago + idx.minutes),
      updated_at: (3.days.ago + idx.minutes)
    )

    Message.create!(
      booking:,
      sender: owner,
      body: Faker::Lorem.sentence(word_count: 12),
      created_at: (2.days.ago + idx.minutes),
      updated_at: (2.days.ago + idx.minutes)
    )

    if idx.even?
      booking.update!(owner_last_read_at: 4.days.ago, user_last_read_at: 1.day.ago)
    else
      booking.update!(owner_last_read_at: Time.current, user_last_read_at: Time.current)
    end
  end
  puts "Messages: #{Message.count}"

  reviewable = bookings.select { |b| b.end_date < today }
  reviewable.first(4).each_with_index do |booking, idx|
    Review.create!(
      booking:,
      user: booking.user,
      rating: (5 - (idx % 2)),
      comment: Faker::Lorem.paragraph(sentence_count: 2)
    )
  end
  puts "Reviews: #{Review.count}"
else
  puts "Skipping demo seed data (development only)."
end

puts "Done."
