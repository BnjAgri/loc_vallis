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

def assert_seed_password!(env_name, password)
  min_length = Devise.password_length.min
  return password if password.length >= min_length

  raise <<~MSG
    Seed password too short for #{env_name}: #{password.length} chars (min #{min_length}).
    Set #{env_name} with at least #{min_length} characters and re-run `rails db:seed`.
  MSG
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

owner_email = Owner.primary_email
owner_password = assert_seed_password!(
  "SEED_OWNER_PASSWORD",
  seed_password(name: "SEED_OWNER_PASSWORD", fallback: "toto123")
)

owner = Owner.find_or_create_by!(email: owner_email) do |o|
  o.password = owner_password
  o.password_confirmation = owner_password
end

# In a single-owner setup, ensure all existing content belongs to the primary owner.
now = Time.current
Room.where.not(owner_id: owner.id).update_all(owner_id: owner.id, updated_at: now) if Room.exists?
Article.where.not(owner_id: owner.id).update_all(owner_id: owner.id, updated_at: now) if Article.exists?

user_email = ENV.fetch("SEED_USER_EMAIL", "user@locvallis.demo")
user_password = assert_seed_password!(
  "SEED_USER_PASSWORD",
  seed_password(name: "SEED_USER_PASSWORD", fallback: "toto123")
)

user = User.find_or_create_by!(email: user_email) do |u|
  u.password = user_password
  u.password_confirmation = user_password
end

puts "Owner: #{owner.email}"
puts "User: #{user.email}"
puts "Passwords: set SEED_OWNER_PASSWORD / SEED_USER_PASSWORD (defaults to 'toto123' in demo mode)"

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

puts "Seeding room reviews (2 per room)…"

REVIEW_WINDOW_START = Date.new(2025, 4, 1)
REVIEW_WINDOW_END = Date.new(2025, 11, 30) # inclusive (booking end_date is exclusive)

REVIEWER_PROFILES = [
  { first_name: "Camille", last_name: "Durand" },
  { first_name: "Thomas", last_name: "Lefèvre" },
  { first_name: "Sarah", last_name: "Moreau" },
  { first_name: "Julien", last_name: "Bernard" },
  { first_name: "Léa", last_name: "Petit" },
  { first_name: "Nicolas", last_name: "Roux" }
].freeze

REVIEW_SNIPPETS = [
  { rating: 5, comment: "Séjour parfait : chambre impeccable, literie très confortable et accueil chaleureux. On reviendra." },
  { rating: 5, comment: "Très bon rapport qualité/prix. Calme la nuit, propre, et tout était conforme aux photos." },
  { rating: 4, comment: "Chambre agréable et bien tenue. Petit bémol sur l'insonorisation, mais globalement très bien." },
  { rating: 5, comment: "Super expérience : arrivée simple, hôte disponible, et emplacement pratique pour visiter." },
  { rating: 4, comment: "Très propre, bien équipé. On a passé 2 nuits au calme, parfait pour une courte escapade." },
  { rating: 5, comment: "Accueil attentionné et chambre lumineuse. Rien à redire, tout était nickel." },
  { rating: 4, comment: "Bonne prestation. La chambre est confortable et on se sent vite à l'aise." }
].freeze

def time_on(date, hour: 12)
  Time.zone.local(date.year, date.month, date.day, hour, 0, 0)
end

def booking_range_ok?(room:, start_date:, end_date:)
  BookingQuote.call(room:, start_date:, end_date:).ok?
end

def ensure_opening_period_for(room:, start_date:, end_date:, currency:, nightly_price_cents:)
  overlap = OpeningPeriod
    .where(room_id: room.id)
    .where("start_date < ? AND end_date > ?", end_date, start_date)
    .exists?

  return false if overlap

  OpeningPeriod.create!(
    room:,
    start_date:,
    end_date:,
    nightly_price_cents:,
    currency:
  )

  true
end

def pick_non_overlapping_stay(room:, avoid_ranges:, window_start:, window_end:)
  durations = [2, 3, 4]
  max_attempts = 40

  max_attempts.times do
    nights = durations.sample
    latest_start = window_end - nights
    next if latest_start < window_start

    start_date = rand(window_start..latest_start)
    end_date = start_date + nights

    next if avoid_ranges.any? { |(s, e)| start_date < e && end_date > s }

    # Also avoid overlap with any reserved booking already in DB.
    overlap = Booking
      .where(room_id: room.id)
      .where(status: Booking::RESERVED_STATUSES)
      .where("start_date < ? AND end_date > ?", end_date, start_date)
      .exists?
    next if overlap

    return [start_date, end_date]
  end

  nil
end

original_send_welcome_emails = ENV["SEND_WELCOME_EMAILS"]
ENV["SEND_WELCOME_EMAILS"] = "false"

begin
  rooms.each do |room|
    existing = room.reviews.count
    missing = [2 - existing, 0].max
    next if missing.zero?

    puts "- #{room.name}: creating #{missing} review(s)…"

    created_ranges = []

    missing.times do |idx|
      stay = pick_non_overlapping_stay(
        room:,
        avoid_ranges: created_ranges,
        window_start: REVIEW_WINDOW_START,
        window_end: REVIEW_WINDOW_END
      )

      if stay.nil?
        puts "  Could not find an available stay window for #{room.name}; skipping."
        break
      end

      start_date, end_date = stay

      unless booking_range_ok?(room:, start_date:, end_date:)
        # If no opening period covers the stay, try to create one exactly for that stay.
        created = ensure_opening_period_for(
          room:,
          start_date:,
          end_date:,
          currency: CURRENCY,
          nightly_price_cents: ENV.fetch("SEED_NIGHTLY_PRICE_CENTS", "12000").to_i
        )

        unless created && booking_range_ok?(room:, start_date:, end_date:)
          puts "  Could not make dates bookable for #{room.name} (#{start_date}..#{end_date}); skipping."
          next
        end
      end

      profile = REVIEWER_PROFILES.sample
      reviewer_email = "reviewer+room#{room.id}-#{idx + 1}@seed.locvallis.invalid"
      reviewer_password = SecureRandom.hex(16)

      reviewer = User.find_or_create_by!(email: reviewer_email) do |u|
        u.first_name = profile[:first_name]
        u.last_name = profile[:last_name]
        u.password = reviewer_password
        u.password_confirmation = reviewer_password
      end

      booking = Booking.create!(
        room:,
        user: reviewer,
        start_date:,
        end_date:,
        status: "confirmed_paid"
      )

      snippet = REVIEW_SNIPPETS.sample
      review = Review.create!(
        booking:,
        user: reviewer,
        rating: snippet[:rating],
        comment: snippet[:comment]
      )

      # Make timestamps consistent with a 2025 stay.
      booking_time = time_on(end_date, hour: 10) - 7.days
      review_time = time_on(end_date, hour: 18) + 2.days
      booking.update_columns(created_at: booking_time, updated_at: booking_time)
      review.update_columns(created_at: review_time, updated_at: review_time)

      created_ranges << [start_date, end_date]
    end
  end
ensure
  if original_send_welcome_emails.nil?
    ENV.delete("SEND_WELCOME_EMAILS")
  else
    ENV["SEND_WELCOME_EMAILS"] = original_send_welcome_emails
  end
end

puts "Reviews: #{Review.count}"
puts "Done."
