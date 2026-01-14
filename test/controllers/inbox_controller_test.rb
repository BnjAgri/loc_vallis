require "test_helper"

class InboxControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = Owner.create!(email: "owner_user_inbox@test.local", password: "password")

    @user = User.create!(email: "user_inbox@test.local", password: "password")
    @other_user = User.create!(email: "user_other_inbox@test.local", password: "password")

    @room = Room.create!(owner: @owner, name: "Room user inbox")

    OpeningPeriod.create!(
      room: @room,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 25),
      nightly_price_cents: 10_000,
      currency: "EUR"
    )

    @booking = Booking.create!(
      room: @room,
      user: @user,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 12)
    )

    @other_booking = Booking.create!(
      room: @room,
      user: @other_user,
      start_date: Date.new(2026, 1, 14),
      end_date: Date.new(2026, 1, 16)
    )

    @booking.messages.create!(sender: @owner, body: "Bonjour")
    @other_booking.messages.create!(sender: @owner, body: "Hello")

    @read_booking = Booking.create!(
      room: @room,
      user: @user,
      start_date: Date.new(2026, 1, 18),
      end_date: Date.new(2026, 1, 20)
    )

    travel_to Time.zone.parse("2026-01-13 11:00:00") do
      @read_booking.messages.create!(sender: @owner, body: "Déjà lu")
    end

    @read_booking.update!(user_last_read_at: Time.zone.parse("2026-01-13 12:00:00"))

    sign_in @user
  end

  test "inbox shows only bookings for current user" do
    get inbox_path
    assert_response :success

    assert_includes @response.body, "Réservation ##{@booking.id}"
    assert_includes @response.body, "Room user inbox"

    refute_includes @response.body, "Réservation ##{@other_booking.id}"
  end

  test "inbox filter unread shows only unread conversations" do
    get inbox_path(filter: "unread")
    assert_response :success

    assert_includes @response.body, "Réservation ##{@booking.id}"
    refute_includes @response.body, "Réservation ##{@read_booking.id}"
  end
end
