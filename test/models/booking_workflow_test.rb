require "test_helper"

class BookingWorkflowTest < ActiveSupport::TestCase
  setup do
    @owner = Owner.create!(email: "owner_flow@test.local", password: "password")
    @user = User.create!(email: "guest_flow@test.local", password: "password")
    @room = Room.create!(owner: @owner, name: "Room")

    OpeningPeriod.create!(
      room: @room,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 20),
      nightly_price_cents: 10_000,
      currency: "EUR"
    )
  end

  test "owner can approve requested booking and sets 48h payment deadline" do
    booking = Booking.create!(room: @room, user: @user, start_date: Date.new(2026, 1, 10), end_date: Date.new(2026, 1, 12))

    travel_to Time.zone.parse("2026-01-05 10:00:00") do
      booking.approve!(by: @owner)
      booking.reload

      assert_equal "approved_pending_payment", booking.status
      assert_equal Time.current, booking.approved_at
      assert_equal 48.hours.from_now, booking.payment_expires_at
      assert booking.payment_window_open?
    end
  end

  test "expire_overdue! marks expired after deadline" do
    booking = Booking.create!(
      room: @room,
      user: @user,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 12),
      status: "approved_pending_payment",
      approved_at: Time.zone.parse("2026-01-01 10:00:00"),
      payment_expires_at: Time.zone.parse("2026-01-03 10:00:00")
    )

    travel_to Time.zone.parse("2026-01-04 10:00:00") do
      Booking.expire_overdue!
      assert_equal "expired", booking.reload.status
    end
  end
end
