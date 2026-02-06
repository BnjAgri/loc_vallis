# frozen_string_literal: true

require "test_helper"
require "ostruct"

class StripeCheckoutSessionCreatorTest < ActiveSupport::TestCase
  setup do
    @owner = Owner.create!(email: "owner_scc@test.local", password: "password")
    @user = User.create!(email: "guest_scc@test.local", password: "password")
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
      end_date: Date.new(2026, 1, 12)
    )

    @booking.update!(
      status: "approved_pending_payment",
      approved_at: Time.current,
      payment_expires_at: 48.hours.from_now
    )
  end

  test "raises when Stripe is not configured" do
    previous_key = Stripe.api_key
    Stripe.api_key = nil

    assert_raises(StandardError) do
      StripeCheckoutSessionCreator.call(
        booking: @booking,
        success_url: "http://example.test/success",
        cancel_url: "http://example.test/cancel"
      )
    end
  ensure
    Stripe.api_key = previous_key
  end

  test "raises when booking is not in payment window" do
    previous_key = Stripe.api_key
    Stripe.api_key = "sk_test"

    @booking.update!(status: "requested")

    assert_raises(StandardError) do
      StripeCheckoutSessionCreator.call(
        booking: @booking,
        success_url: "http://example.test/success",
        cancel_url: "http://example.test/cancel"
      )
    end
  ensure
    Stripe.api_key = previous_key
  end

  test "creates a checkout session and persists ids" do
    previous_key = Stripe.api_key
    Stripe.api_key = "sk_test"

    fake_session = OpenStruct.new(
      id: "cs_test_123",
      url: "https://checkout.stripe.test/session",
      payment_intent: "pi_test_123"
    )

    captured_args = nil
    original = Stripe::Checkout::Session.method(:create)
    Stripe::Checkout::Session.define_singleton_method(:create) do |args|
      captured_args = args
      fake_session
    end

    session = StripeCheckoutSessionCreator.call(
      booking: @booking,
      success_url: "http://example.test/success",
      cancel_url: "http://example.test/cancel"
    )

    assert_equal fake_session, session

    @booking.reload
    assert_equal "cs_test_123", @booking.stripe_checkout_session_id
    assert_equal "pi_test_123", @booking.stripe_payment_intent_id

    assert_equal "payment", captured_args[:mode]
    assert_equal @booking.id, captured_args[:client_reference_id]
    assert_equal({ booking_id: @booking.id }, captured_args[:metadata])

    line_item = captured_args[:line_items].first
    assert_equal 1, line_item[:quantity]
    assert_equal "eur", line_item.dig(:price_data, :currency)
    assert_equal 20_000, line_item.dig(:price_data, :unit_amount)
  ensure
    Stripe::Checkout::Session.define_singleton_method(:create, original) if original
    Stripe.api_key = previous_key
  end
end
