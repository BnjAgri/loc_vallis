require "test_helper"

module Admin
  class ClientsControllerTest < ActionDispatch::IntegrationTest
    test "index lists only users who booked owner's rooms" do
      owner = Owner.create!(email: "owner_clients_index@test.local", password: "password")
      other_owner = Owner.create!(email: "owner_other_clients_index@test.local", password: "password")

      room = Room.new(owner:, name: "Owner room")
      room.save!(validate: false)

      other_room = Room.new(owner: other_owner, name: "Other room")
      other_room.save!(validate: false)

      OpeningPeriod.create!(room:, start_date: Date.current - 30, end_date: Date.current + 60, nightly_price_cents: 10_00, currency: "EUR")
      OpeningPeriod.create!(room: other_room, start_date: Date.current - 30, end_date: Date.current + 60, nightly_price_cents: 10_00, currency: "EUR")

      user1 = User.create!(email: "client1@test.local", password: "password", first_name: "Alice")
      user2 = User.create!(email: "client2@test.local", password: "password", first_name: "Bob")

      Booking.create!(room:, user: user1, start_date: Date.current + 10, end_date: Date.current + 12, status: "requested")
      Booking.create!(room: other_room, user: user2, start_date: Date.current + 10, end_date: Date.current + 12, status: "requested")

      sign_in owner

      get admin_clients_path
      assert_response :success

      assert_includes response.body, "Alice"
      assert_not_includes response.body, "Bob"
    end

    test "index sorts by next booking date (closest first)" do
      owner = Owner.create!(email: "owner_clients_sort@test.local", password: "password")
      room = Room.new(owner:, name: "Owner room")
      room.save!(validate: false)

      OpeningPeriod.create!(room:, start_date: Date.current - 30, end_date: Date.current + 60, nightly_price_cents: 10_00, currency: "EUR")

      near_user = User.create!(email: "near@test.local", password: "password", first_name: "Near")
      far_user = User.create!(email: "far@test.local", password: "password", first_name: "Far")

      Booking.create!(room:, user: far_user, start_date: Date.current + 20, end_date: Date.current + 22, status: "requested")
      Booking.create!(room:, user: near_user, start_date: Date.current + 5, end_date: Date.current + 7, status: "requested")

      sign_in owner

      get admin_clients_path
      assert_response :success

      near_index = response.body.index("Near")
      far_index = response.body.index("Far")
      assert near_index.present? && far_index.present?, "Expected both users to appear in the response"
      assert_operator near_index, :<, far_index
    end

    test "index can sort alphabetically (asc)" do
      owner = Owner.create!(email: "owner_clients_sort_alpha@test.local", password: "password")
      room = Room.new(owner:, name: "Owner room")
      room.save!(validate: false)

      OpeningPeriod.create!(room:, start_date: Date.current - 30, end_date: Date.current + 60, nightly_price_cents: 10_00, currency: "EUR")

      a_user = User.create!(email: "alpha_a@test.local", password: "password", first_name: "Alice", last_name: "Aaa")
      b_user = User.create!(email: "alpha_b@test.local", password: "password", first_name: "Bob", last_name: "Bbb")

      Booking.create!(room:, user: b_user, start_date: Date.current + 20, end_date: Date.current + 22, status: "requested")
      Booking.create!(room:, user: a_user, start_date: Date.current + 25, end_date: Date.current + 27, status: "requested")

      sign_in owner

      get admin_clients_path(sort: "alpha", direction: "asc")
      assert_response :success

      a_index = response.body.index("Alice")
      b_index = response.body.index("Bob")
      assert a_index.present? && b_index.present?, "Expected both users to appear in the response"
      assert_operator a_index, :<, b_index
    end

    test "index shows current booking status or last relevant booking date/status" do
      owner = Owner.create!(email: "owner_clients_status@test.local", password: "password")
      room = Room.new(owner:, name: "Owner room")
      room.save!(validate: false)

      OpeningPeriod.create!(room:, start_date: Date.current - 30, end_date: Date.current + 60, nightly_price_cents: 10_00, currency: "EUR")

      current_user = User.create!(email: "current@test.local", password: "password", first_name: "Current")
      past_user = User.create!(email: "past@test.local", password: "password", first_name: "Past")

      Booking.create!(room:, user: current_user, start_date: Date.current - 1, end_date: Date.current + 1, status: "confirmed_paid")
      Booking.create!(room:, user: past_user, start_date: Date.current - 10, end_date: Date.current - 8, status: "canceled")

      sign_in owner

      get admin_clients_path
      assert_response :success

      assert_includes response.body, I18n.t("bookings.statuses.confirmed_paid")
      assert_includes response.body, I18n.l((Date.current - 1).to_date)
      assert_includes response.body, I18n.t("bookings.statuses.canceled")
      assert_includes response.body, I18n.l((Date.current - 10).to_date)
    end

    test "show displays next booking and history" do
      owner = Owner.create!(email: "owner_clients_show@test.local", password: "password")
      room = Room.new(owner:, name: "Owner room")
      room.save!(validate: false)

      OpeningPeriod.create!(room:, start_date: Date.current - 30, end_date: Date.current + 60, nightly_price_cents: 10_00, currency: "EUR")
      user = User.create!(email: "client_show@test.local", password: "password", first_name: "Celine")

      past = Booking.create!(room:, user:, start_date: Date.current - 10, end_date: Date.current - 8, status: "confirmed_paid")
      upcoming = Booking.create!(room:, user:, start_date: Date.current + 3, end_date: Date.current + 5, status: "requested")

      Message.create!(booking: upcoming, sender: user, body: "Bonjour")
      Review.create!(booking: past, user:, rating: 5, comment: "Super")

      sign_in owner

      get admin_client_path(id: user)
      assert_response :success

      assert_includes response.body, "Celine"
      assert_includes response.body, "Owner room"
      assert_includes response.body, "Bonjour"
      assert_includes response.body, "Super"
    end

    test "requires owner authentication" do
      get admin_clients_path
      assert_response :redirect
    end

    test "destroy is blocked when client has active bookings" do
      owner = Owner.create!(email: "owner_clients_destroy_blocked@test.local", password: "password")
      room = Room.new(owner:, name: "Owner room")
      room.save!(validate: false)
      OpeningPeriod.create!(room:, start_date: Date.current - 30, end_date: Date.current + 60, nightly_price_cents: 10_00, currency: "EUR")

      user = User.create!(email: "client_destroy_blocked@test.local", password: "password", first_name: "Blocked")
      Booking.create!(room:, user:, start_date: Date.current + 3, end_date: Date.current + 5, status: "requested")

      sign_in owner

      assert_no_difference("User.count") do
        delete admin_client_path(id: user)
      end

      assert_redirected_to admin_client_path(id: user)
      assert_equal "Des réservations sont actives pour cet utilisateur. Veuillez les annuler d'abord.", flash[:alert]
    end

    test "destroy deletes client when no active bookings" do
      owner = Owner.create!(email: "owner_clients_destroy_ok@test.local", password: "password")
      room = Room.new(owner:, name: "Owner room")
      room.save!(validate: false)
      OpeningPeriod.create!(room:, start_date: Date.current - 30, end_date: Date.current + 60, nightly_price_cents: 10_00, currency: "EUR")

      user = User.create!(email: "client_destroy_ok@test.local", password: "password", first_name: "Ok")
      Booking.create!(room:, user:, start_date: Date.current + 3, end_date: Date.current + 5, status: "canceled")

      sign_in owner

      assert_difference("User.count", -1) do
        delete admin_client_path(id: user)
      end

      assert_redirected_to admin_clients_path
      assert_equal "Profil utilisateur supprimé.", flash[:notice]
    end
  end
end
