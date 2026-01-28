# frozen_string_literal: true

# Usage:
#   bin/rails runner script/send_booking_user_mail_flow.rb you@example.com
#
# Options:
#   DRY_RUN=true    -> don't send, only print subjects
#   LOCALE=fr|en    -> choose locale (default: fr)

require "date"

email = ARGV[0].to_s.strip
raise "usage: bin/rails runner script/send_booking_user_mail_flow.rb <email>" if email.blank?

dry_run = ENV.fetch("DRY_RUN", "false") == "true"
I18n.locale = ENV.fetch("LOCALE", "fr").to_sym

owner = Owner.new(email: email, guesthouse_name: "Gîte Loc Vallis")
room = Room.new(name: "Chambre 1", owner: owner)
user = User.new(email: email, first_name: "Benjamin", last_name: "Masson")

start_date = Date.today + 7
end_date = Date.today + 10

booking = Booking.new(
  id: 123,
  room: room,
  user: user,
  start_date: start_date,
  end_date: end_date,
  total_price_cents: 45000,
  currency: "EUR",
  status: "requested",
  payment_expires_at: Time.current + 48.hours,
  stripe_refund_id: "re_test_123"
)

flow = []

# Notifications a user might receive (some are alternate branches; we send all for review).
flow << BookingMailer.with(booking: booking, override_to: email).requested
flow << BookingMailer.with(booking: booking, override_to: email).approved
flow << BookingMailer.with(booking: booking, override_to: email).declined
flow << BookingMailer.with(booking: booking, override_to: email).confirmed
flow << BookingMailer.with(booking: booking, override_to: email, canceled_by: "owner").canceled
flow << BookingMailer.with(booking: booking, override_to: email).expired
flow << BookingMailer.with(booking: booking, override_to: email).refunded
flow << BookingMailer.with(booking: booking, override_to: email).review_request

# A typical message notification received by the user (message sent by owner).
message = Message.new(
  booking: booking,
  sender: owner,
  body: "Bonjour ! Petite précision pour votre arrivée : check-in à partir de 16h."
)
flow << MessageMailer.with(message: message, override_to: email).new_message

puts "Delivery method: #{ActionMailer::Base.delivery_method}"
puts "Locale: #{I18n.locale}"
puts "To: #{email}"
puts "Count: #{flow.size}"
puts

flow.each_with_index do |mail, idx|
  subject = mail.subject
  puts "#{idx + 1}. #{subject}"

  next if dry_run

  mail.deliver_now
end

puts
puts(dry_run ? "DRY_RUN: not sent" : "Sent")
