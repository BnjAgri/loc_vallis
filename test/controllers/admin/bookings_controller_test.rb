require "test_helper"

class Admin::BookingsControllerTest < ActionDispatch::IntegrationTest
  test "index paginates reservations and recent messages (10 per page)" do
    owner = Owner.create!(email: "owner_admin_bookings_pag@test.local", password: "password")
    room = Room.new(owner:, name: "Room admin bookings")
    room.save!(validate: false)

    OpeningPeriod.create!(
      room:,
      start_date: Date.current - 30,
      end_date: Date.current + 365,
      nightly_price_cents: 10_00,
      currency: "EUR"
    )

    users = (1..21).map do |i|
      User.create!(email: "bookings_pag_#{i}@test.local", password: "password")
    end

    bookings = users.map.with_index do |user, i|
      Booking.create!(
        room:,
        user:,
        start_date: Date.current + (i + 1),
        end_date: Date.current + (i + 2),
        status: "requested"
      )
    end

    bookings.each_with_index do |booking, i|
      booking.messages.create!(sender: booking.user, body: "Message#{i + 1}")
    end

    sign_in owner

    get admin_bookings_path
    assert_response :success

    assert_match(/>Message21</, response.body)
    refute_match(/>Message11</, response.body)
    assert_includes response.body, "messages_page=2"
    assert_includes response.body, "messages_page=3"

    assert_includes response.body, "href=\"/admin/bookings/#{bookings.last.id}\">##{bookings.last.id}"
    assert_not_includes response.body, "href=\"/admin/bookings/#{bookings[10].id}\">##{bookings[10].id}"
    assert_includes response.body, "bookings_page=2"
    assert_includes response.body, "bookings_page=3"

    get admin_bookings_path(messages_page: 2)
    assert_response :success
    assert_match(/>Message11</, response.body)
    refute_match(/>Message1</, response.body)

    get admin_bookings_path(messages_page: 3)
    assert_response :success
    assert_match(/>Message1</, response.body)

    get admin_bookings_path(bookings_page: 3)
    assert_response :success
    assert_includes response.body, "href=\"/admin/bookings/#{bookings.first.id}\">##{bookings.first.id}"
  end
end
