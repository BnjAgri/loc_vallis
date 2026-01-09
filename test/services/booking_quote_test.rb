require "test_helper"

class BookingQuoteTest < ActiveSupport::TestCase
  setup do
    @owner = Owner.create!(email: "owner_quote@test.local", password: "password")
    @user = User.create!(email: "guest_quote@test.local", password: "password")
    @room = Room.create!(owner: @owner, name: "Room")

    OpeningPeriod.create!(
      room: @room,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 20),
      nightly_price_cents: 10_000,
      currency: "EUR"
    )
  end

  test "returns total and currency for valid range" do
    result = BookingQuote.call(room: @room, start_date: Date.new(2026, 1, 10), end_date: Date.new(2026, 1, 13))

    assert result.ok?
    assert_equal 3, result.nights
    assert_equal 10_000, result.nightly_price_cents
    assert_equal "EUR", result.currency
    assert_equal 30_000, result.total_price_cents
  end

  test "rejects range outside opening period" do
    result = BookingQuote.call(room: @room, start_date: Date.new(2026, 1, 9), end_date: Date.new(2026, 1, 12))

    assert_not result.ok?
    assert_includes result.error, "opening period"
  end

  test "rejects overlap with reserved booking" do
    Booking.create!(
      room: @room,
      user: @user,
      start_date: Date.new(2026, 1, 12),
      end_date: Date.new(2026, 1, 14),
      status: "approved_pending_payment"
    )

    result = BookingQuote.call(room: @room, start_date: Date.new(2026, 1, 13), end_date: Date.new(2026, 1, 15))

    assert_not result.ok?
    assert_includes result.error, "overlap"
  end
end
