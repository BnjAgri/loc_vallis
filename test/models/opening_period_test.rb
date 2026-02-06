require "test_helper"

class OpeningPeriodTest < ActiveSupport::TestCase
  test "requires end_date to be after start_date" do
    owner = Owner.create!(email: "owner_period_dates@test.local", password: "password")
    room = Room.create!(owner:, name: "Room")

    period = OpeningPeriod.new(
      room:,
      start_date: Date.new(2026, 1, 20),
      end_date: Date.new(2026, 1, 10),
      nightly_price_cents: 10_000,
      currency: "EUR"
    )

    assert_not period.valid?
    assert_includes period.errors.details[:end_date], { error: :after_start_date }

    I18n.with_locale(:fr) do
      period.valid?
      assert_includes period.errors.full_messages.join(" "), "doit être après la date de début"
    end
  end

  test "disallows overlapping opening periods for a room" do
    owner = Owner.create!(email: "owner_period@test.local", password: "password")
    room = Room.create!(owner:, name: "Room")

    OpeningPeriod.create!(
      room:,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 20),
      nightly_price_cents: 10_000,
      currency: "EUR"
    )

    overlap = OpeningPeriod.new(
      room:,
      start_date: Date.new(2026, 1, 15),
      end_date: Date.new(2026, 1, 25),
      nightly_price_cents: 12_000,
      currency: "EUR"
    )

    assert_not overlap.valid?
    assert_includes overlap.errors.full_messages.join(" "), "overlaps"
  end

  test "allows non-overlapping opening periods for a room" do
    owner = Owner.create!(email: "owner_period2@test.local", password: "password")
    room = Room.create!(owner:, name: "Room")

    OpeningPeriod.create!(
      room:,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 20),
      nightly_price_cents: 10_000,
      currency: "EUR"
    )

    non_overlap = OpeningPeriod.new(
      room:,
      start_date: Date.new(2026, 1, 20),
      end_date: Date.new(2026, 1, 25),
      nightly_price_cents: 12_000,
      currency: "EUR"
    )

    assert non_overlap.valid?
  end
end
