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

puts "Seeding…"

# In production (e.g. Heroku), we only seed when explicitly asked.
seed_demo = ENV["SEED_DEMO"].to_s.downcase.in?(["1", "true", "yes"])
seed_allowed = Rails.env.development? || seed_demo

unless seed_allowed
  puts "Skipping demo seed data. Set SEED_DEMO=1 to seed in #{Rails.env}."
  puts "Done."
  exit(0)
end

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

def seed_password(name:, fallback:)
  ENV.fetch(name, fallback).to_s
end

today = Date.current

if Rails.env.development?
  puts "Cleaning existing data (development only)…"
  Message.delete_all
  Review.delete_all
  Booking.delete_all
  OpeningPeriod.delete_all
  Room.delete_all
  Article.delete_all
  User.delete_all
  Owner.delete_all
end

owner_email = ENV.fetch("SEED_OWNER_EMAIL", "owner@locvallis.demo")
owner_password = seed_password(name: "SEED_OWNER_PASSWORD", fallback: "toto")

owner = Owner.find_or_create_by!(email: owner_email) do |o|
  o.password = owner_password
  o.password_confirmation = owner_password
end

user_email = ENV.fetch("SEED_USER_EMAIL", "user@locvallis.demo")
user_password = seed_password(name: "SEED_USER_PASSWORD", fallback: "toto")

user = User.find_or_create_by!(email: user_email) do |u|
  u.password = user_password
  u.password_confirmation = user_password
end

puts "Owner: #{owner.email}"
puts "User: #{user.email}"
puts "Passwords: set SEED_OWNER_PASSWORD / SEED_USER_PASSWORD (defaults to 'toto' in demo mode)"

# Create up to 2 rooms (the app has an MVP hard limit at 2).
room_specs = [
  {
    name: "Chambre 1",
    description: "Chambre lumineuse et confortable, idéale pour un séjour au calme.",
    capacity: 2,
    room_url: seeded_room_image_url
  },
  {
    name: "Chambre 2",
    description: "Chambre spacieuse avec une belle vue, parfaite pour se ressourcer.",
    capacity: 4,
    room_url: seeded_room_image_url
  }
]

rooms = room_specs.filter_map do |spec|
  Room.find_by(owner: owner, name: spec[:name]) || begin
    Room.create!(
      owner: owner,
      name: spec[:name],
      description: spec[:description],
      capacity: spec[:capacity],
      room_url: spec[:room_url]
    )
  rescue ActiveRecord::RecordInvalid
    # If the MVP limit is reached (or any other validation), skip creating extra rooms.
    nil
  end
end

puts "Rooms present: #{Room.count}"

rooms.each do |room|
  # One broad opening period, idempotent via room+dates.
  start_date = today - 60
  end_date = today + 180
  OpeningPeriod.find_or_create_by!(room: room, start_date: start_date, end_date: end_date) do |op|
    op.nightly_price_cents = ENV.fetch("SEED_NIGHTLY_PRICE_CENTS", "12000").to_i
    op.currency = CURRENCY
  end
end

puts "Opening periods: #{OpeningPeriod.count}"
puts "Done."
