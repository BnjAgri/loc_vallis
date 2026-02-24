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

  test "approved sends to user and owner" do
    owner = Owner.create!(email: "owner_booking_mailer_approved@test.local", password: "password")
    user = User.create!(email: "user_booking_mailer_approved@test.local", password: "password")
    room = Room.create!(owner:, name: "Room")

    booking = Booking.new(
      room:,
      user:,
      start_date: Date.current,
      end_date: Date.current + 2,
      status: "approved_pending_payment",
      payment_expires_at: 2.days.from_now
    )
    booking.save!(validate: false)

    email = BookingMailer.with(booking:).approved
    assert_equal [user.email, owner.email], email.to
  end

  test "approved supports override_to" do
    owner = Owner.create!(email: "owner_booking_mailer_override@test.local", password: "password")
    user = User.create!(email: "user_booking_mailer_override@test.local", password: "password")
    room = Room.create!(owner:, name: "Room")

    booking = Booking.new(
      room:,
      user:,
      start_date: Date.current,
      end_date: Date.current + 2,
      status: "approved_pending_payment",
      payment_expires_at: 2.days.from_now
    )
    booking.save!(validate: false)

    email = BookingMailer.with(booking:, override_to: "override@test.local").approved
    assert_equal ["override@test.local"], email.to
  end
end
