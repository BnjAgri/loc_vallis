require "test_helper"

class BookingMailerTest < ActionMailer::TestCase
  test "requested sends only to user" do
    owner = Owner.create!(email: "owner_booking_mailer@test.local", password: "password")
    user = User.create!(email: "user_booking_mailer@test.local", password: "password", first_name: "Jean", last_name: "User")
    room = Room.create!(owner:, name: "Room")

    OpeningPeriod.create!(
      room:,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 20),
      nightly_price_cents: 10_00,
      currency: "EUR"
    )

    booking = Booking.create!(
      room:,
      user:,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 12),
      status: "requested"
    )

    email = BookingMailer.with(booking:).requested
    assert_equal [user.email], email.to
  end

  test "requested_owner sends only to owner" do
    owner = Owner.create!(email: "owner_booking_mailer_owner@test.local", password: "password")
    user = User.create!(email: "user_booking_mailer_owner@test.local", password: "password", first_name: "Jean", last_name: "User")
    room = Room.create!(owner:, name: "Room")

    OpeningPeriod.create!(
      room:,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 20),
      nightly_price_cents: 10_00,
      currency: "EUR"
    )

    booking = Booking.create!(
      room:,
      user:,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 12),
      status: "requested"
    )

    email = BookingMailer.with(booking:).requested_owner
    assert_equal [owner.email], email.to
  end
end
