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

  test "refund (full) sets status to refunded and stores refund metadata" do
    refund = OpenStruct.new(id: "re_test_123")
    captured_args = nil

    original = Stripe::Refund.method(:create)
    Stripe::Refund.define_singleton_method(:create) do |args|
      captured_args = args
      refund
    end

    post refund_admin_booking_path(id: @booking)
    assert_response :redirect

    assert_equal({ payment_intent: "pi_test_999" }, captured_args)

    @booking.reload
    assert_equal "refunded", @booking.status
    assert_equal "re_test_123", @booking.stripe_refund_id
    assert_not_nil @booking.refunded_at
  ensure
    Stripe::Refund.define_singleton_method(:create, original)
  end

  test "refund (partial) passes amount to Stripe" do
    refund = OpenStruct.new(id: "re_test_456")
    captured_args = nil

    original = Stripe::Refund.method(:create)
    Stripe::Refund.define_singleton_method(:create) do |args|
      captured_args = args
      refund
    end

    post refund_admin_booking_path(id: @booking), params: { amount_cents: 12_34 }
    assert_response :redirect

    assert_equal({ payment_intent: "pi_test_999", amount: 12_34 }, captured_args)

    @booking.reload
    assert_equal "refunded", @booking.status
    assert_equal "re_test_456", @booking.stripe_refund_id
  ensure
    Stripe::Refund.define_singleton_method(:create, original)
  end
end
