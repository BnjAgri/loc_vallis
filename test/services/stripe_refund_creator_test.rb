# frozen_string_literal: true

require "test_helper"
require "ostruct"

class StripeRefundCreatorTest < ActiveSupport::TestCase
  setup do
    @owner = Owner.create!(email: "owner_src@test.local", password: "password")
    @user = User.create!(email: "guest_src@test.local", password: "password")
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
      stripe_payment_intent_id: "pi_test_999",
      total_price_cents: 20_000,
      currency: "EUR"
    )
  end

  test "raises when Stripe is not configured" do
    previous_key = Stripe.api_key
    Stripe.api_key = nil

    assert_raises(StandardError) do
      StripeRefundCreator.call(booking: @booking)
    end
  ensure
    Stripe.api_key = previous_key
  end

  test "creates a full refund and marks booking refunded" do
    previous_key = Stripe.api_key
    Stripe.api_key = "sk_test"

    original_pi = Stripe::PaymentIntent.method(:retrieve)
    Stripe::PaymentIntent.define_singleton_method(:retrieve) { |_id| OpenStruct.new(amount_received: 20_000) }

    refund = OpenStruct.new(id: "re_test_123")
    captured_args = nil
    original_refund = Stripe::Refund.method(:create)
    Stripe::Refund.define_singleton_method(:create) do |args|
      captured_args = args
      refund
    end

    travel_to Time.zone.parse("2026-01-08 10:00:00") do
      result = StripeRefundCreator.call(booking: @booking)
      assert_equal refund, result

      assert_equal({ payment_intent: "pi_test_999" }, captured_args)

      @booking.reload
      assert_equal "refunded", @booking.status
      assert_equal "re_test_123", @booking.stripe_refund_id
      assert_equal Time.current, @booking.refunded_at
    end
  ensure
    Stripe::Refund.define_singleton_method(:create, original_refund) if original_refund
    Stripe::PaymentIntent.define_singleton_method(:retrieve, original_pi) if original_pi
    Stripe.api_key = previous_key
  end

  test "creates a partial refund with amount" do
    previous_key = Stripe.api_key
    Stripe.api_key = "sk_test"

    original_pi = Stripe::PaymentIntent.method(:retrieve)
    Stripe::PaymentIntent.define_singleton_method(:retrieve) { |_id| OpenStruct.new(amount_received: 20_000) }

    refund = OpenStruct.new(id: "re_test_456")
    captured_args = nil
    original_refund = Stripe::Refund.method(:create)
    Stripe::Refund.define_singleton_method(:create) do |args|
      captured_args = args
      refund
    end

    StripeRefundCreator.call(booking: @booking, amount_cents: 12_34)

    assert_equal({ payment_intent: "pi_test_999", amount: 12_34 }, captured_args)

    @booking.reload
    assert_equal "refunded", @booking.status
    assert_equal "re_test_456", @booking.stripe_refund_id
  ensure
    Stripe::Refund.define_singleton_method(:create, original_refund) if original_refund
    Stripe::PaymentIntent.define_singleton_method(:retrieve, original_pi) if original_pi
    Stripe.api_key = previous_key
  end

  test "rejects a refund amount exceeding amount paid" do
    previous_key = Stripe.api_key
    Stripe.api_key = "sk_test"

    original_pi = Stripe::PaymentIntent.method(:retrieve)
    Stripe::PaymentIntent.define_singleton_method(:retrieve) { |_id| OpenStruct.new(amount_received: 10_000) }

    assert_raises(StandardError) do
      StripeRefundCreator.call(booking: @booking, amount_cents: 12_000)
    end
  ensure
    Stripe::PaymentIntent.define_singleton_method(:retrieve, original_pi) if original_pi
    Stripe.api_key = previous_key
  end
end
