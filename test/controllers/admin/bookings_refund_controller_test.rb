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
      stripe_payment_intent_id: "pi_test_999",
      total_price_cents: 20_000,
      currency: "EUR"
    )

    @original_payment_intent_retrieve = Stripe::PaymentIntent.method(:retrieve)
    Stripe::PaymentIntent.define_singleton_method(:retrieve) do |_id|
      OpenStruct.new(amount_received: 20_000)
    end

    sign_in @owner
  end

  teardown do
    Stripe::PaymentIntent.define_singleton_method(:retrieve, @original_payment_intent_retrieve)
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

  test "refund is not allowed for a different owner" do
    other_owner = Owner.create!(email: "owner_other_refund@test.local", password: "password")
    sign_in other_owner

    called = false
    original = Stripe::Refund.method(:create)
    Stripe::Refund.define_singleton_method(:create) do |_args|
      called = true
      OpenStruct.new(id: "re_should_not_happen")
    end

    post refund_admin_booking_path(id: @booking), headers: { "HTTP_REFERER" => admin_booking_path(id: @booking) }
    assert_response :redirect
    assert_redirected_to admin_booking_path(id: @booking)
    assert_equal I18n.t("shared.authorization.not_authorized"), flash[:alert]
    assert_equal false, called

    @booking.reload
    assert_equal "confirmed_paid", @booking.status
    assert_nil @booking.stripe_refund_id
  ensure
    Stripe::Refund.define_singleton_method(:create, original)
  end

  test "refund rejects an amount exceeding the total" do
    post refund_admin_booking_path(id: @booking), params: { amount_cents: 99_999 }, headers: { "HTTP_REFERER" => admin_booking_path(id: @booking) }
    assert_response :redirect
    assert_redirected_to admin_booking_path(id: @booking)
    assert_equal "Refund amount exceeds total", flash[:alert]

    @booking.reload
    assert_equal "confirmed_paid", @booking.status
    assert_nil @booking.stripe_refund_id
  end

  test "refund cannot be performed twice" do
    refund = OpenStruct.new(id: "re_test_once")
    called = 0
    original = Stripe::Refund.method(:create)
    Stripe::Refund.define_singleton_method(:create) do |_args|
      called += 1
      refund
    end

    post refund_admin_booking_path(id: @booking), headers: { "HTTP_REFERER" => admin_booking_path(id: @booking) }
    assert_response :redirect

    @booking.reload
    assert_equal "refunded", @booking.status
    assert_equal "re_test_once", @booking.stripe_refund_id
    assert_equal 1, called

    post refund_admin_booking_path(id: @booking), headers: { "HTTP_REFERER" => admin_booking_path(id: @booking) }
    assert_response :redirect
    assert_equal I18n.t("shared.authorization.not_authorized"), flash[:alert]
    assert_equal 1, called
  ensure
    Stripe::Refund.define_singleton_method(:create, original)
  end

  test "refund is rejected when booking is not confirmed_paid" do
    @booking.update!(status: "canceled")

    called = false
    original = Stripe::Refund.method(:create)
    Stripe::Refund.define_singleton_method(:create) do |_args|
      called = true
      OpenStruct.new(id: "re_should_not_happen")
    end

    post refund_admin_booking_path(id: @booking), headers: { "HTTP_REFERER" => admin_booking_path(id: @booking) }
    assert_response :redirect
    assert_redirected_to admin_booking_path(id: @booking)
    assert_equal I18n.t("shared.authorization.not_authorized"), flash[:alert]
    assert_equal false, called
  ensure
    Stripe::Refund.define_singleton_method(:create, original)
  end

  test "refund is rejected when payment_intent is missing" do
    @booking.update!(stripe_payment_intent_id: nil)

    called = false
    original = Stripe::Refund.method(:create)
    Stripe::Refund.define_singleton_method(:create) do |_args|
      called = true
      OpenStruct.new(id: "re_should_not_happen")
    end

    post refund_admin_booking_path(id: @booking), headers: { "HTTP_REFERER" => admin_booking_path(id: @booking) }
    assert_response :redirect
    assert_redirected_to admin_booking_path(id: @booking)
    assert_equal "Missing Stripe payment_intent", flash[:alert]
    assert_equal false, called
  ensure
    Stripe::Refund.define_singleton_method(:create, original)
  end

  test "refund cannot exceed amount actually paid" do
    @booking.update!(total_price_cents: 50_000)

    original = Stripe::PaymentIntent.method(:retrieve)
    Stripe::PaymentIntent.define_singleton_method(:retrieve) do |_id|
      OpenStruct.new(amount_received: 10_000)
    end

    post refund_admin_booking_path(id: @booking), params: { amount_cents: 12_000 }, headers: { "HTTP_REFERER" => admin_booking_path(id: @booking) }
    assert_response :redirect
    assert_redirected_to admin_booking_path(id: @booking)
    assert_equal "Refund amount exceeds amount paid", flash[:alert]

    @booking.reload
    assert_equal "confirmed_paid", @booking.status
    assert_nil @booking.stripe_refund_id
  ensure
    Stripe::PaymentIntent.define_singleton_method(:retrieve, original)
  end
end
