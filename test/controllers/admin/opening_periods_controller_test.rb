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
        post admin_room_opening_periods_path(room_id: room), params: {
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

    test "edit loads and update accepts euros" do
      owner = Owner.create!(
        email: "owner_op_edit@example.com",
        password: "password123",
        first_name: "Claude",
        last_name: "Owner"
      )

      room = Room.create!(owner:, name: "Chambre OP edit", capacity: 2)

      opening_period = OpeningPeriod.create!(
        room:,
        start_date: Date.current + 10,
        end_date: Date.current + 20,
        nightly_price_cents: 10_00,
        currency: "EUR"
      )

      sign_in owner

      get edit_admin_room_opening_period_path(room_id: room, id: opening_period)
      assert_response :success

      patch admin_room_opening_period_path(room_id: room, id: opening_period), params: {
        opening_period: {
          start_date: (Date.current + 11).to_s,
          end_date: (Date.current + 21).to_s,
          nightly_price_euros: "22.00",
          currency: "EUR"
        }
      }

      assert_redirected_to admin_room_path(id: room)
      opening_period.reload
      assert_equal 2200, opening_period.nightly_price_cents
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
        delete admin_room_opening_period_path(room_id: room, id: opening_period)
      end

      assert_redirected_to admin_room_path(id: room)
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
        delete admin_room_opening_period_path(room_id: room, id: opening_period)
      end

      assert_redirected_to admin_room_path(id: room)
    end

    test "block splits opening period when removing a middle range" do
      owner = Owner.create!(email: "owner_op_split@example.com", password: "password123")
      room = Room.create!(owner:, name: "Chambre OP split", capacity: 2)

      opening_period = OpeningPeriod.create!(
        room:,
        start_date: Date.current + 10,
        end_date: Date.current + 20,
        nightly_price_cents: 10_00,
        currency: "EUR"
      )

      sign_in owner

      assert_difference("OpeningPeriod.count", 1) do
        patch block_admin_room_opening_period_path(room_id: room, id: opening_period), params: {
          block: {
            start_date: (Date.current + 12).to_s,
            end_date: (Date.current + 15).to_s
          }
        }
      end

      assert_redirected_to admin_room_path(id: room)

      periods = room.opening_periods.order(:start_date).to_a
      assert_equal 2, periods.size
      assert_equal (Date.current + 10), periods[0].start_date
      assert_equal (Date.current + 12), periods[0].end_date
      assert_equal (Date.current + 15), periods[1].start_date
      assert_equal (Date.current + 20), periods[1].end_date
      assert_equal 10_00, periods[0].nightly_price_cents
      assert_equal 10_00, periods[1].nightly_price_cents
    end

    test "block shortens opening period when removing from the start" do
      owner = Owner.create!(email: "owner_op_shorten_start@example.com", password: "password123")
      room = Room.create!(owner:, name: "Chambre OP shorten start", capacity: 2)

      opening_period = OpeningPeriod.create!(
        room:,
        start_date: Date.current + 10,
        end_date: Date.current + 20,
        nightly_price_cents: 10_00,
        currency: "EUR"
      )

      sign_in owner

      assert_no_difference("OpeningPeriod.count") do
        patch block_admin_room_opening_period_path(room_id: room, id: opening_period), params: {
          block: {
            start_date: (Date.current + 10).to_s,
            end_date: (Date.current + 12).to_s
          }
        }
      end

      assert_redirected_to admin_room_path(id: room)
      opening_period.reload
      assert_equal (Date.current + 12), opening_period.start_date
      assert_equal (Date.current + 20), opening_period.end_date
    end

    test "block is rejected when range overlaps an upcoming requested booking" do
      owner = Owner.create!(email: "owner_op_block_overlap@example.com", password: "password123")
      user = User.create!(email: "user_op_block_overlap@example.com", password: "password123")
      room = Room.create!(owner:, name: "Chambre OP overlap", capacity: 2)

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
        start_date: Date.current + 13,
        end_date: Date.current + 14,
        status: "requested"
      )

      sign_in owner

      assert_no_difference("OpeningPeriod.count") do
        patch block_admin_room_opening_period_path(room_id: room, id: opening_period), params: {
          block: {
            start_date: (Date.current + 12).to_s,
            end_date: (Date.current + 15).to_s
          }
        }
      end

      assert_redirected_to edit_admin_room_opening_period_path(room_id: room, id: opening_period)
      assert_match(/overlapping an existing booking/i, flash[:alert].to_s)
    end
  end
end
