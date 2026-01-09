require "test_helper"
require "ostruct"

class Admin::BookingsRefundControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = Owner.create!(email: "owner_refund@test.local", password: "password")
    @user = User.create!(email: "guest_refund@test.local", password: "password")
    @room = Room.create!(owner: @owner, name: "Room")

    OpeningPeriod.create!(
      room: @room,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 20),
      nightly_price_cents: 10_000,
      currency: "EUR"
    )

    @booking = Booking.create!(
      room: @room,
      user: @user,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 12),
      status: "confirmed_paid",
      stripe_payment_intent_id: "pi_test_999"
    )

    sign_in @owner
  end

  test "refund sets status to refunded and stores refund metadata" do
    refund = OpenStruct.new(id: "re_test_123")

    original = Stripe::Refund.method(:create)
    Stripe::Refund.define_singleton_method(:create) { |_args| refund }

    post refund_admin_booking_path(@booking)
    assert_response :redirect

    @booking.reload
    assert_equal "refunded", @booking.status
    assert_equal "re_test_123", @booking.stripe_refund_id
    assert_not_nil @booking.refunded_at
  ensure
    Stripe::Refund.define_singleton_method(:create, original)
  end
end
