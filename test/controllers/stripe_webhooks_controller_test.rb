require "test_helper"
require "ostruct"

class StripeWebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = Owner.create!(email: "owner_wh@test.local", password: "password")
    @user = User.create!(email: "guest_wh@test.local", password: "password")
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

  test "checkout.session.completed confirms booking" do
    session = OpenStruct.new(
      id: "cs_test_123",
      payment_intent: "pi_test_123",
      metadata: OpenStruct.new(booking_id: @booking.id)
    )

    event = OpenStruct.new(
      type: "checkout.session.completed",
      data: OpenStruct.new(object: session)
    )

    previous_secret = ENV["STRIPE_WEBHOOK_SECRET"]
    ENV["STRIPE_WEBHOOK_SECRET"] = "whsec_test"

    original = Stripe::Webhook.method(:construct_event)
    Stripe::Webhook.define_singleton_method(:construct_event) { |_payload, _sig_header, _secret| event }

    post "/stripe/webhook", headers: { "HTTP_STRIPE_SIGNATURE" => "sig" }, params: "{}"
    assert_response :ok

    @booking.reload
    assert_equal "confirmed_paid", @booking.status
    assert_equal "cs_test_123", @booking.stripe_checkout_session_id
    assert_equal "pi_test_123", @booking.stripe_payment_intent_id
  ensure
    Stripe::Webhook.define_singleton_method(:construct_event, original)
    ENV["STRIPE_WEBHOOK_SECRET"] = previous_secret
  end
end
