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

  test "index sorts bookings by client name" do
    owner = Owner.create!(email: "owner_admin_bookings_sort@test.local", password: "password")
    room = Room.new(owner:, name: "Room admin bookings sort")
    room.save!(validate: false)

    OpeningPeriod.create!(
      room:,
      start_date: Date.current - 30,
      end_date: Date.current + 365,
      nightly_price_cents: 10_00,
      currency: "EUR"
    )

    user_b = User.create!(email: "b_user@test.local", password: "password", first_name: "Zoé", last_name: "Bailly")
    user_a = User.create!(email: "a_user@test.local", password: "password", first_name: "Alice", last_name: "Armand")

    booking_b = Booking.create!(room:, user: user_b, start_date: Date.current + 10, end_date: Date.current + 11, status: "requested")
    booking_a = Booking.create!(room:, user: user_a, start_date: Date.current + 12, end_date: Date.current + 13, status: "requested")

    sign_in owner

    get admin_bookings_path(sort: "client", direction: "asc")
    assert_response :success

    pos_a = response.body.index("href=\"/admin/bookings/#{booking_a.id}\">##{booking_a.id}")
    pos_b = response.body.index("href=\"/admin/bookings/#{booking_b.id}\">##{booking_b.id}")
    assert pos_a && pos_b
    assert_operator pos_a, :<, pos_b
  end

  test "owner cannot cancel a confirmed_paid booking without refund" do
    owner = Owner.create!(email: "owner_admin_cancel_paid@test.local", password: "password")
    user = User.create!(email: "guest_admin_cancel_paid@test.local", password: "password")

    room = Room.new(owner:, name: "Room cancel paid")
    room.save!(validate: false)

    OpeningPeriod.create!(
      room:,
      start_date: Date.current - 30,
      end_date: Date.current + 365,
      nightly_price_cents: 10_00,
      currency: "EUR"
    )

    booking = Booking.create!(
      room:,
      user:,
      start_date: Date.current + 10,
      end_date: Date.current + 12,
      status: "confirmed_paid",
      total_price_cents: 20_00,
      currency: "EUR",
      stripe_payment_intent_id: "pi_test_cancel_paid"
    )

    sign_in owner

    patch cancel_admin_booking_path(id: booking), headers: { "HTTP_REFERER" => admin_booking_path(id: booking) }
    assert_response :redirect
    assert_redirected_to admin_booking_path(id: booking)
    assert_equal I18n.t("shared.authorization.not_authorized"), flash[:alert]

    booking.reload
    assert_equal "confirmed_paid", booking.status
  end

  test "owner can cancel a requested booking" do
    owner = Owner.create!(email: "owner_admin_cancel_requested@test.local", password: "password")
    user = User.create!(email: "guest_admin_cancel_requested@test.local", password: "password")

    room = Room.new(owner:, name: "Room cancel requested")
    room.save!(validate: false)

    OpeningPeriod.create!(
      room:,
      start_date: Date.current - 30,
      end_date: Date.current + 365,
      nightly_price_cents: 10_00,
      currency: "EUR"
    )

    booking = Booking.create!(
      room:,
      user:,
      start_date: Date.current + 20,
      end_date: Date.current + 22,
      status: "requested"
    )

    sign_in owner

    patch cancel_admin_booking_path(id: booking), headers: { "HTTP_REFERER" => admin_booking_path(id: booking) }
    assert_response :redirect

    booking.reload
    assert_equal "canceled", booking.status
  end
end
