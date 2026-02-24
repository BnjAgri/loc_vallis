require "test_helper"

class MessageMailerTest < ActionMailer::TestCase
  test "new_message sends to owner when sender is a user" do
    owner = Owner.create!(email: "owner_message_mailer@test.local", password: "password")
    user = User.create!(email: "user_message_mailer@test.local", password: "password")
    room = Room.create!(owner:, name: "Room")

    booking = Booking.new(room:, user:, start_date: Date.current, end_date: Date.current + 2)
    booking.save!(validate: false)

    message = Message.new(booking:, sender: user, body: "Hello")

    email = MessageMailer.with(message:).new_message
    assert_equal [owner.email], email.to
    assert_includes email.subject, booking.id.to_s
  end

  test "new_message sends to user when sender is an owner" do
    owner = Owner.create!(email: "owner_message_mailer_owner@test.local", password: "password")
    user = User.create!(email: "user_message_mailer_owner@test.local", password: "password")
    room = Room.create!(owner:, name: "Room")

    booking = Booking.new(room:, user:, start_date: Date.current, end_date: Date.current + 2)
    booking.save!(validate: false)

    message = Message.new(booking:, sender: owner, body: "Bonjour")

    email = MessageMailer.with(message:).new_message
    assert_equal [user.email], email.to
    assert_includes email.subject, booking.id.to_s
  end

  test "new_message supports override_to" do
    owner = Owner.create!(email: "owner_message_mailer_override@test.local", password: "password")
    user = User.create!(email: "user_message_mailer_override@test.local", password: "password")
    room = Room.create!(owner:, name: "Room")

    booking = Booking.new(room:, user:, start_date: Date.current, end_date: Date.current + 2)
    booking.save!(validate: false)

    message = Message.new(booking:, sender: user, body: "Hello")

    email = MessageMailer.with(message:, override_to: "override@test.local").new_message
    assert_equal ["override@test.local"], email.to
  end
end
