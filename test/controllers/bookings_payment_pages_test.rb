require "test_helper"

class BookingsPaymentPagesTest < ActionDispatch::IntegrationTest
  test "signed-in user can view payment success page" do
    user = User.create!(email: "pay_success_user@test.local", password: "password")
    sign_in user

    owner = Owner.create!(email: "pay_success_owner@test.local", password: "password")
    room = Room.new(owner: owner, name: "Test room")
    room.save!(validate: false)

    booking = Booking.new(
      room: room,
      user: user,
      start_date: Date.current,
      end_date: Date.current + 2,
      status: "approved_pending_payment",
      total_price_cents: 12_300,
      currency: "EUR",
      payment_expires_at: 1.day.from_now
    )
    booking.save!(validate: false)

    get payment_success_booking_path(id: booking)
    assert_response :success
  end

  test "signed-in user can view payment cancel page" do
    user = User.create!(email: "pay_cancel_user@test.local", password: "password")
    sign_in user

    owner = Owner.create!(email: "pay_cancel_owner@test.local", password: "password")
    room = Room.new(owner: owner, name: "Test room")
    room.save!(validate: false)

    booking = Booking.new(
      room: room,
      user: user,
      start_date: Date.current,
      end_date: Date.current + 2,
      status: "approved_pending_payment",
      total_price_cents: 12_300,
      currency: "EUR",
      payment_expires_at: 1.day.from_now
    )
    booking.save!(validate: false)

    get payment_cancel_booking_path(id: booking)
    assert_response :success
  end
end
