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

    OpeningPeriod.create!(
      room: @room,
      start_date: Date.new(2026, 1, 20),
      end_date: Date.new(2026, 1, 25),
      nightly_price_cents: 20_000,
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

  test "includes optional services total in the quote" do
    result = BookingQuote.call(
      room: @room,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 13),
      optional_services_total_cents: 1_500
    )

    assert result.ok?
    assert_equal 31_500, result.total_price_cents
    assert_equal 1_500, result.optional_services_total_cents
  end

  test "rejects range outside opening period" do
    result = BookingQuote.call(room: @room, start_date: Date.new(2026, 1, 9), end_date: Date.new(2026, 1, 12))

    assert_not result.ok?
    assert_equal I18n.t("booking_quote.errors.dates_not_covered"), result.error
  end

  test "supports a range spanning multiple contiguous opening periods" do
    result = BookingQuote.call(room: @room, start_date: Date.new(2026, 1, 18), end_date: Date.new(2026, 1, 22))

    assert result.ok?
    assert_equal 4, result.nights
    assert_equal "EUR", result.currency
    assert_equal 60_000, result.total_price_cents
    assert_nil result.nightly_price_cents, "Expected nightly_price_cents to be nil when multiple rates apply"
    assert_equal 2, result.opening_periods.size
  end

  test "rejects a range with a gap between opening periods" do
    OpeningPeriod.where(room: @room).where(start_date: Date.new(2026, 1, 20)).delete_all

    OpeningPeriod.create!(
      room: @room,
      start_date: Date.new(2026, 1, 21),
      end_date: Date.new(2026, 1, 25),
      nightly_price_cents: 20_000,
      currency: "EUR"
    )

    result = BookingQuote.call(room: @room, start_date: Date.new(2026, 1, 19), end_date: Date.new(2026, 1, 22))

    assert_not result.ok?
    assert_equal I18n.t("booking_quote.errors.dates_not_covered"), result.error
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
    assert_equal I18n.t("booking_quote.errors.dates_overlap_booking"), result.error
  end
end
