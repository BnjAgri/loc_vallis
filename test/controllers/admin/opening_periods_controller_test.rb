require "test_helper"

module Admin
  class OpeningPeriodsControllerTest < ActionDispatch::IntegrationTest
    test "create stores nightly price from euros" do
      owner = Owner.create!(
        email: "owner_op_create@example.com",
        password: "password123",
        first_name: "Claude",
        last_name: "Owner"
      )

      room = Room.create!(owner:, name: "Chambre OP create", capacity: 2)

      sign_in owner

      assert_difference("OpeningPeriod.count", 1) do
        post admin_room_opening_periods_path(room), params: {
          opening_period: {
            start_date: (Date.current + 10).to_s,
            end_date: (Date.current + 12).to_s,
            nightly_price_euros: "12,50",
            currency: "EUR"
          }
        }
      end

      opening_period = OpeningPeriod.order(:created_at).last
      assert_equal 1250, opening_period.nightly_price_cents
      assert_equal "EUR", opening_period.currency
    end

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
