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
end
