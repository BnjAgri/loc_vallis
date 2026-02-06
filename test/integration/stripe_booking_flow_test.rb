# frozen_string_literal: true

require "test_helper"
require "ostruct"

class StripeBookingFlowTest < ActionDispatch::IntegrationTest
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

    @booking = Booking.create!(
      room: @room,
      user: @user,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 12),
      status: "approved_pending_payment",
      approved_at: Time.zone.parse("2026-01-05 10:00:00"),
      payment_expires_at: Time.zone.parse("2026-01-07 10:00:00")
    )
  end

  test "checkout then webhook completion confirms the booking" do
    previous_key = Stripe.api_key
    Stripe.api_key = "sk_test"

    fake_session = OpenStruct.new(
      id: "cs_test_123",
      url: "https://checkout.stripe.test/session",
      payment_intent: "pi_test_123"
    )

    original_checkout_create = Stripe::Checkout::Session.method(:create)
    Stripe::Checkout::Session.define_singleton_method(:create) { |_args| fake_session }

    travel_to Time.zone.parse("2026-01-06 10:00:00") do
      sign_in @user

      post checkout_booking_path(id: @booking.id)

      assert_response :see_other
      assert_equal "https://checkout.stripe.test/session", response.headers["Location"]

      @booking.reload
      assert_equal "cs_test_123", @booking.stripe_checkout_session_id
      assert_equal "pi_test_123", @booking.stripe_payment_intent_id

      previous_secret = ENV["STRIPE_WEBHOOK_SECRET"]
      ENV["STRIPE_WEBHOOK_SECRET"] = "whsec_test"

      session_obj = OpenStruct.new(
        id: "cs_test_123",
        payment_intent: "pi_test_123",
        payment_status: "paid",
        metadata: OpenStruct.new(booking_id: @booking.id)
      )

      event = OpenStruct.new(
        type: "checkout.session.completed",
        data: OpenStruct.new(object: session_obj)
      )

      original_construct = Stripe::Webhook.method(:construct_event)
      Stripe::Webhook.define_singleton_method(:construct_event) { |_payload, _sig_header, _secret| event }

      post "/stripe/webhook", headers: { "HTTP_STRIPE_SIGNATURE" => "sig" }, params: "{}"
      assert_response :ok

      @booking.reload
      assert_equal "confirmed_paid", @booking.status
    ensure
      Stripe::Webhook.define_singleton_method(:construct_event, original_construct) if original_construct
      ENV["STRIPE_WEBHOOK_SECRET"] = previous_secret
    end
  ensure
    Stripe::Checkout::Session.define_singleton_method(:create, original_checkout_create) if original_checkout_create
    Stripe.api_key = previous_key
  end

  test "webhook does not confirm an expired payment window" do
    previous_secret = ENV["STRIPE_WEBHOOK_SECRET"]
    original_construct = nil

    travel_to Time.zone.parse("2026-01-07 10:00:01") do
      ENV["STRIPE_WEBHOOK_SECRET"] = "whsec_test"

      session_obj = OpenStruct.new(
        id: "cs_test_999",
        payment_intent: "pi_test_999",
        payment_status: "paid",
        metadata: OpenStruct.new(booking_id: @booking.id)
      )

      event = OpenStruct.new(
        type: "checkout.session.completed",
        data: OpenStruct.new(object: session_obj)
      )

      original_construct = Stripe::Webhook.method(:construct_event)
      Stripe::Webhook.define_singleton_method(:construct_event) { |_payload, _sig_header, _secret| event }

      post "/stripe/webhook", headers: { "HTTP_STRIPE_SIGNATURE" => "sig" }, params: "{}"
      assert_response :ok

      @booking.reload
      assert_equal "approved_pending_payment", @booking.status
    end
  ensure
    Stripe::Webhook.define_singleton_method(:construct_event, original_construct) if original_construct
    ENV["STRIPE_WEBHOOK_SECRET"] = previous_secret
  end
end
