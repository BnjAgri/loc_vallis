require "test_helper"

class BookingTest < ActiveSupport::TestCase
  setup do
    @owner = Owner.create!(email: "owner_booking@test.local", password: "password")
    @user = User.create!(email: "guest_booking@test.local", password: "password")
    @room = Room.create!(owner: @owner, name: "Room")

    OpeningPeriod.create!(
      room: @room,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 20),
      nightly_price_cents: 10_000,
      currency: "EUR"
    )
  end

  test "booking must be fully inside one opening period" do
    booking = Booking.new(
      room: @room,
      user: @user,
      start_date: Date.new(2026, 1, 9),
      end_date: Date.new(2026, 1, 12)
    )

    assert_not booking.valid?
    assert_includes booking.errors.full_messages.join(" "), "inside one opening period"
  end

  test "booking populates total price from opening period" do
    booking = Booking.create!(
      room: @room,
      user: @user,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 13)
    )

    assert_equal 3, booking.nights
    assert_equal 30_000, booking.total_price_cents
    assert_equal "EUR", booking.currency
    assert_equal "requested", booking.status
  end

  test "booking request cannot overlap reserved bookings" do
    Booking.create!(
      room: @room,
      user: @user,
      start_date: Date.new(2026, 1, 12),
      end_date: Date.new(2026, 1, 14),
      status: "confirmed_paid"
    )

    overlapping = Booking.new(
      room: @room,
      user: @user,
      start_date: Date.new(2026, 1, 13),
      end_date: Date.new(2026, 1, 15)
    )

    assert_not overlapping.valid?
    assert_includes overlapping.errors.full_messages.join(" "), "overlap"
  end
end
