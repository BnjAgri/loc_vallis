require "test_helper"

module Admin
  class OpeningPeriodsControllerTest < ActionDispatch::IntegrationTest
    test "destroy is blocked when opening period overlaps upcoming requested booking" do
      owner = Owner.create!(
        email: "owner_op_block@example.com",
        password: "password123",
        first_name: "Claude",
        last_name: "Owner"
      )

      user = User.create!(
        email: "user_op_block@example.com",
        password: "password123",
        first_name: "Jean",
        last_name: "User"
      )

      room = Room.create!(owner:, name: "Chambre OP", capacity: 2)

      opening_period = OpeningPeriod.create!(
        room:,
        start_date: Date.current + 10,
        end_date: Date.current + 20,
        nightly_price_cents: 10_00,
        currency: "EUR"
      )

      Booking.create!(
        room:,
        user:,
        start_date: Date.current + 12,
        end_date: Date.current + 15,
        status: "requested"
      )

      sign_in owner

      assert_no_difference("OpeningPeriod.count") do
        delete admin_room_opening_period_path(room, opening_period)
      end

      assert_redirected_to admin_room_path(room)
      assert_equal "Réservations à venir, suppression impossible", flash[:alert]
    end

    test "destroy is allowed when opening period has no blocking bookings" do
      owner = Owner.create!(
        email: "owner_op_allowed@example.com",
        password: "password123",
        first_name: "Claude",
        last_name: "Owner"
      )

      user = User.create!(
        email: "user_op_allowed@example.com",
        password: "password123",
        first_name: "Jean",
        last_name: "User"
      )

      room = Room.create!(owner:, name: "Chambre OP 2", capacity: 2)

      opening_period = OpeningPeriod.create!(
        room:,
        start_date: Date.current + 10,
        end_date: Date.current + 20,
        nightly_price_cents: 10_00,
        currency: "EUR"
      )

      Booking.create!(
        room:,
        user:,
        start_date: Date.current + 12,
        end_date: Date.current + 15,
        status: "canceled"
      )

      sign_in owner

      assert_difference("OpeningPeriod.count", -1) do
        delete admin_room_opening_period_path(room, opening_period)
      end

      assert_redirected_to admin_room_path(room)
    end
  end
end
