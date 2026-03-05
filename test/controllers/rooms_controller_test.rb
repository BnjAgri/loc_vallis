require "test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  test "show enables checkout day for consecutive opening days" do
    owner = Owner.create!(
      email: "owner_rooms_show_enabled_ranges@example.com",
      password: "password123",
      first_name: "Claude",
      last_name: "Owner"
    )

    room = Room.create!(owner:, name: "Chambre test", capacity: 2)

    # Two consecutive one-night opening periods: [10,11) and [11,12)
    room.opening_periods.create!(
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 11),
      nightly_price_cents: 10_00,
      currency: "EUR"
    )

    room.opening_periods.create!(
      start_date: Date.new(2026, 1, 11),
      end_date: Date.new(2026, 1, 12),
      nightly_price_cents: 10_00,
      currency: "EUR"
    )

    travel_to Time.zone.parse("2026-01-10 10:00:00") do
      get room_path(id: room.id)
      assert_response :ok

      assert_select "input[data-controller='availability-calendar']" do |elements|
        enabled_json = elements.first["data-availability-calendar-enabled-ranges-value"]
        enabled = JSON.parse(enabled_json)

        # We expect a single merged range, extended to include the checkout day.
        assert_equal [{ "from" => "2026-01-10", "to" => "2026-01-12" }], enabled
      end
    end
  end
end
