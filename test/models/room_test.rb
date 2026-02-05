require "test_helper"

class RoomTest < ActiveSupport::TestCase
  test "enforces MVP hard limit of 2 rooms" do
    owner = Owner.create!(email: "owner_room@test.local", password: "password")

    while Room.count < 2
      Room.create!(owner:, name: "Room #{Room.count + 1}")
    end

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

  test "capacity must be an integer (localized error message in fr)" do
    owner = Owner.create!(email: "owner_capacity@test.local", password: "password")

    I18n.with_locale(:fr) do
      room = Room.new(owner:, name: "Room", capacity: 2.5)
      assert_not room.valid?

      messages = room.errors.full_messages.join(" ")
      assert_includes messages, "Capacité"
      assert_includes messages, "entier"
      assert_not_includes messages.downcase, "translation missing"
    end
  end

  test "room form fields have no missing i18n translations (fr)" do
    owner = Owner.create!(email: "owner_room_i18n@test.local", password: "password")

    I18n.with_locale(:fr) do
      room = Room.new(
        owner:,
        name: nil,
        capacity: 2.5,
        optional_services: 6.times.map { |i| { "name" => "Option #{i}", "price_eur" => "1" } }
      )

      room.photos.attach(io: StringIO.new("not an image"), filename: "not-an-image.txt", content_type: "text/plain")

      assert_not room.valid?

      messages = room.errors.full_messages.join(" \n")
      assert_not_includes messages.downcase, "translation missing"
    end
  end

  test "rejects angle brackets in editable text fields" do
    owner = Owner.create!(email: "owner_room_angle@test.local", password: "password")

    room = Room.new(
      owner:,
      name: "Chambre <b>1</b>",
      description: "Description > unsafe",
      room_url: "https://example.com/image.png?<script>"
    )

    assert_not room.valid?
    messages = room.errors.full_messages.join(" ")
    assert_includes messages, "ne doit pas contenir < ou >"
  end

  test "image_urls filters out non-http(s) values" do
    owner = Owner.create!(email: "owner_room_urls_filter@test.local", password: "password")

    room = Room.new(
      owner:,
      name: "Room",
      room_url: "https://example.com/a.jpg\n<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>\njavascript:alert(1)\nftp://example.com/a.jpg"
    )

    assert_equal ["https://example.com/a.jpg"], room.image_urls
  end

  test "rejects angle brackets in optional service names" do
    owner = Owner.create!(email: "owner_room_services_angle@test.local", password: "password")

    room = Room.new(
      owner:,
      name: "Room",
      optional_services: [{ "name" => "Petit <dej>", "price_eur" => "5" }]
    )

    assert_not room.valid?
    messages = room.errors.full_messages.join(" ")
    assert_includes messages, "ne doit pas contenir < ou >"
  end
end
