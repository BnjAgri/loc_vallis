require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = Owner.create!(email: "owner_msg@test.local", password: "password")
    @user = User.create!(email: "guest_msg@test.local", password: "password")
    @other_user = User.create!(email: "intruder_msg@test.local", password: "password")

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
  end

  test "owner can send a message to the guest" do
    sign_in @owner

    assert_difference "@booking.messages.count", +1 do
      post booking_messages_path(booking_id: @booking), params: { message: { body: "Bonjour" } }
    end

    assert_redirected_to admin_booking_path(id: @booking)
    assert_equal "Owner", @booking.messages.last.sender_type
    assert_equal @owner.id, @booking.messages.last.sender_id
  end

  test "guest can send a message to the owner" do
    sign_in @user

    assert_difference "@booking.messages.count", +1 do
      post booking_messages_path(booking_id: @booking), params: { message: { body: "Hello" } }
    end

    assert_redirected_to booking_path(id: @booking)
    assert_equal "User", @booking.messages.last.sender_type
    assert_equal @user.id, @booking.messages.last.sender_id
  end

  test "non-participant cannot send a message" do
    sign_in @other_user

    assert_no_difference "@booking.messages.count" do
      post booking_messages_path(booking_id: @booking), params: { message: { body: "Hacked" } }
    end

    assert_redirected_to root_path
    assert_equal I18n.t("shared.authorization.not_authorized"), flash[:alert]
  end
end
