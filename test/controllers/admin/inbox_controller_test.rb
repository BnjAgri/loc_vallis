require "test_helper"

class Admin::InboxControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = Owner.create!(email: "owner_inbox@test.local", password: "password")
    @other_owner = Owner.create!(email: "owner_other@test.local", password: "password")

    @user = User.create!(email: "guest_inbox@test.local", password: "password")
    @room = Room.create!(owner: @owner, name: "Room inbox")
    @other_room = Room.create!(owner: @other_owner, name: "Other room")

    OpeningPeriod.create!(
      room: @room,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 20),
      nightly_price_cents: 10_000,
      currency: "EUR"
    )

    OpeningPeriod.create!(
      room: @other_room,
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

    @other_booking = Booking.create!(
      room: @other_room,
      user: @user,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 12)
    )

    @booking.messages.create!(sender: @user, body: "Bonjour")
    @other_booking.messages.create!(sender: @user, body: "Hello")

    @read_booking = Booking.create!(
      room: @room,
      user: @user,
      start_date: Date.new(2026, 1, 14),
      end_date: Date.new(2026, 1, 16)
    )
    travel_to Time.zone.parse("2026-01-13 11:00:00") do
      @read_booking.messages.create!(sender: @user, body: "Déjà lu")
    end

    @read_booking.update!(owner_last_read_at: Time.zone.parse("2026-01-13 12:00:00"))

    sign_in @owner
  end

  test "inbox shows only bookings for current owner" do
    get admin_inbox_path
    assert_response :success

    assert_includes @response.body, "Booking ##{@booking.id}"
    assert_includes @response.body, "Room inbox"

    refute_includes @response.body, "Booking ##{@other_booking.id}"
    refute_includes @response.body, "Other room"
  end

  test "inbox filter unread shows only unread conversations" do
    get admin_inbox_path(filter: "unread")
    assert_response :success

    assert_includes @response.body, "Booking ##{@booking.id}"
    refute_includes @response.body, "Booking ##{@read_booking.id}"
  end
end
