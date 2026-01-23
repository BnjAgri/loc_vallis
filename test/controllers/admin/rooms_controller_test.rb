require "test_helper"

module Admin
  class RoomsControllerTest < ActionDispatch::IntegrationTest
    test "destroy is blocked when room has upcoming requested booking" do
      owner = Owner.create!(
        email: "owner_destroy_block@example.com",
        password: "password123",
        first_name: "Claude",
        last_name: "Owner"
      )

      user = User.create!(
        email: "user_destroy_block@example.com",
        password: "password123",
        first_name: "Jean",
        last_name: "User"
      )

      room = Room.create!(owner:, name: "Chambre test", capacity: 2)

      OpeningPeriod.create!(
        room:,
        start_date: Date.current + 10,
        end_date: Date.current + 15,
        nightly_price_cents: 10_00,
        currency: "EUR"
      )

      Booking.create!(
        room:,
        user:,
        start_date: Date.current + 10,
        end_date: Date.current + 12,
        status: "requested"
      )

      sign_in owner

      assert_no_difference("Room.count") do
        delete admin_room_path(id: room)
      end

      assert_redirected_to admin_room_path(id: room)
      assert_equal "Réservations à venir, suppression impossible", flash[:alert]
    end

    test "destroy is allowed when room has only non-blocking bookings" do
      owner = Owner.create!(
        email: "owner_destroy_allowed@example.com",
        password: "password123",
        first_name: "Claude",
        last_name: "Owner"
      )

      user = User.create!(
        email: "user_destroy_allowed@example.com",
        password: "password123",
        first_name: "Jean",
        last_name: "User"
      )

      room = Room.create!(owner:, name: "Chambre test 2", capacity: 2)

      OpeningPeriod.create!(
        room:,
        start_date: Date.current + 10,
        end_date: Date.current + 15,
        nightly_price_cents: 10_00,
        currency: "EUR"
      )

      Booking.create!(
        room:,
        user:,
        start_date: Date.current + 10,
        end_date: Date.current + 12,
        status: "canceled"
      )

      sign_in owner

      assert_difference("Room.count", -1) do
        delete admin_room_path(id: room)
      end

      assert_redirected_to admin_rooms_path
    end
  end
end
