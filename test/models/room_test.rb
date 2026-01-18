require "test_helper"

class RoomTest < ActiveSupport::TestCase
  test "enforces MVP hard limit of 2 rooms" do
    owner = Owner.create!(email: "owner_room@test.local", password: "password")

    Room.create!(owner:, name: "Room 1")
    Room.create!(owner:, name: "Room 2")

    third = Room.new(owner:, name: "Room 3")
    assert_not third.valid?
    assert_includes third.errors.full_messages.join(" "), "maximum 2 rooms"
  end

  test "normalizes optional services (name + price_eur -> price_cents)" do
    owner = Owner.create!(email: "owner_services@test.local", password: "password")

    room = Room.create!(
      owner:,
      name: "Room with options",
      optional_services: [
        { "name" => "Petit-déjeuner", "price_eur" => "8.50" },
        { "name" => "  ", "price_eur" => "" }
      ]
    )

    assert_equal 1, room.optional_services.size
    assert_equal "Petit-déjeuner", room.optional_services.first["name"]
    assert_equal 850, room.optional_services.first["price_cents"]
    assert_equal "EUR", room.optional_services.first["currency"]
  end

  test "rejects more than 5 optional services" do
    owner = Owner.create!(email: "owner_services_max@test.local", password: "password")

    services = 6.times.map { |i| { "name" => "Option #{i}", "price_eur" => "1" } }
    room = Room.new(owner:, name: "Room max", optional_services: services)

    assert_not room.valid?
    assert_includes room.errors.full_messages.join(" "), "maximum 5"
  end
end
