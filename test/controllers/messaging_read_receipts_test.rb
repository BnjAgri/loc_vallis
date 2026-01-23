require "test_helper"

class MessagingReadReceiptsTest < ActionDispatch::IntegrationTest
  setup do
    @owner = Owner.create!(email: "owner_read@test.local", password: "password")
    @user = User.create!(email: "guest_read@test.local", password: "password")
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

  test "owner booking show marks conversation as read" do
    @booking.messages.create!(sender: @user, body: "Bonjour")

    travel_to Time.zone.parse("2026-01-13 10:00:00") do
      sign_in @owner
      get admin_booking_path(id: @booking)
      assert_response :success

      @booking.reload
      assert_equal Time.current, @booking.owner_last_read_at
    end
  end

  test "user booking show marks conversation as read" do
    @booking.messages.create!(sender: @owner, body: "Hello")

    travel_to Time.zone.parse("2026-01-13 11:00:00") do
      sign_in @user
      get booking_path(id: @booking)
      assert_response :success

      @booking.reload
      assert_equal Time.current, @booking.user_last_read_at
    end
  end
end
