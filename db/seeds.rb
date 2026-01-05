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

puts "Seeding…"

if Rails.env.development?
	puts "Cleaning existing data (development only)…"
	Message.delete_all
	Booking.delete_all
	OpeningPeriod.delete_all
	Room.delete_all
	User.delete_all
	Owner.delete_all
end

PASSWORD = "password123".freeze
CURRENCY = "EUR".freeze

owner = Owner.find_or_create_by!(email: "owner@locvallis.test") do |o|
	o.password = PASSWORD
	o.password_confirmation = PASSWORD
end

puts "Owner: #{owner.email} / #{PASSWORD}"

rooms = Room.where(owner_id: owner.id).order(:created_at).to_a
needed = 2 - rooms.size
needed.times do
	rooms << Room.create!(
		owner:,
		name: Faker::Commerce.unique.product_name,
		description: Faker::Lorem.paragraph(sentence_count: 2),
		capacity: [1, 2].sample
	)
end

rooms = Room.where(owner_id: owner.id).order(:created_at).limit(2).to_a
puts "Rooms: #{rooms.map(&:name).join(", ")}" 

rooms.each do |room|
	next if room.opening_periods.exists?

	OpeningPeriod.create!(
		room:,
		start_date: Date.current,
		end_date: Date.current + 180,
		nightly_price_cents: rand(8_000..18_000),
		currency: CURRENCY
	)
end

users = []
5.times do
	users << User.create!(
		email: Faker::Internet.unique.email,
		password: PASSWORD,
		password_confirmation: PASSWORD
	)
end
puts "Users: #{users.size} created (password: #{PASSWORD})"

def create_booking!(room:, user:, start_date:, nights:)
	Booking.create!(
		room:,
		user:,
		start_date:,
		end_date: start_date + nights
	)
end

def fake_stripe_ids!
	{
		stripe_checkout_session_id: "cs_test_#{SecureRandom.hex(10)}",
		stripe_payment_intent_id: "pi_test_#{SecureRandom.hex(10)}"
	}
end

bookings = []

# Create 8 non-overlapping bookings (4 per room)
rooms.each_with_index do |room, room_index|
	base = Date.current + 10 + (room_index * 60)

	# 1) requested
	bookings << create_booking!(room:, user: users.sample, start_date: base + 0, nights: 3)

	# 2) approved_pending_payment
	b2 = create_booking!(room:, user: users.sample, start_date: base + 7, nights: 2)
	b2.approve!(by: owner)
	bookings << b2

	# 3) confirmed_paid
	b3 = create_booking!(room:, user: users.sample, start_date: base + 14, nights: 4)
	b3.approve!(by: owner)
	b3.update!(status: "confirmed_paid", **fake_stripe_ids!)
	bookings << b3

	# 4) refunded
	b4 = create_booking!(room:, user: users.sample, start_date: base + 25, nights: 2)
	b4.approve!(by: owner)
	b4.update!(status: "confirmed_paid", **fake_stripe_ids!)
	b4.update!(
		status: "refunded",
		stripe_refund_id: "re_test_#{SecureRandom.hex(10)}",
		refunded_at: Time.current
	)
	bookings << b4
end

puts "Bookings: #{bookings.size} created"
puts "Done."
