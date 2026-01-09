require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "requires a body" do
    owner = Owner.create!(email: "owner_msg@test.local", password: "password")
    user = User.create!(email: "guest_msg@test.local", password: "password")
    room = Room.create!(owner:, name: "Room")
    OpeningPeriod.create!(
      room:,
      start_date: Date.new(2026, 1, 10),
      end_date: Date.new(2026, 1, 20),
      nightly_price_cents: 10_000,
      currency: "EUR"
    )
    booking = Booking.create!(room:, user:, start_date: Date.new(2026, 1, 10), end_date: Date.new(2026, 1, 11))

    message = Message.new(booking:, sender: user, body: "")
    assert_not message.valid?
  end
end
