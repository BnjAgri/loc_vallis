# frozen_string_literal: true

# Usage (development):
#   bin/rails runner script/send_user_mail_flow.rb benovert@gmail.com
#
# This script triggers the main user-facing emails end-to-end:
# - welcome email
# - booking requested
# - booking approved (payment required)
# - booking confirmed
# - message notification (owner -> user)
# - review request

email = ARGV[0].to_s.strip
abort("Usage: bin/rails runner script/send_user_mail_flow.rb user@email") if email.blank?

ActiveRecord::Base.transaction do
  # Keep it idempotent-ish: reuse user if already exists.
  user = User.find_or_initialize_by(email: email)
  if user.new_record?
    user.password = "password"
    user.save!
  end

  owner = Owner.find_or_create_by!(email: "owner_for_mail_flow@example.test") do |o|
    o.password = "password"
  end

  room = Room.first || Room.create!(owner: owner, name: "Demo room")

  desired_start = Date.current
  desired_end = Date.current + 30.days

  period = OpeningPeriod.where(room: room).order(:start_date).first
  if period.nil?
    period = OpeningPeriod.create!(
      room: room,
      start_date: desired_start,
      end_date: desired_end,
      nightly_price_cents: 10_000,
      currency: "EUR"
    )
  else
    # Expand the existing period if needed (avoid overlap validations).
    new_start = [period.start_date, desired_start].min
    new_end = [period.end_date, desired_end].max
    period.update!(start_date: new_start, end_date: new_end)
  end

  booking = Booking.where(room: room, user: user).order(created_at: :desc).first

  if booking.nil?
    desired_start = period.start_date + 7.days
    desired_end = period.start_date + 10.days

    # Find a non-overlapping slot inside the opening period.
    start_date = desired_start
    end_date = desired_end

    existing_ranges = Booking.where(room: room).pluck(:start_date, :end_date)
    25.times do
      overlaps = existing_ranges.any? { |(s, e)| s < end_date && e > start_date }
      break unless overlaps

      start_date += 7.days
      end_date += 7.days
    end

    booking = Booking.create!(
      room: room,
      user: user,
      start_date: start_date,
      end_date: end_date
    )
  end

  puts "Sending emails to: #{email}"

  UserMailer.with(user: user).welcome.deliver_now
  BookingMailer.with(booking: booking).requested.deliver_now

  booking.update!(status: "approved_pending_payment", approved_at: Time.current, payment_expires_at: 48.hours.from_now)
  BookingMailer.with(booking: booking).approved.deliver_now

  booking.update!(status: "confirmed_paid")
  BookingMailer.with(booking: booking).confirmed.deliver_now

  message = Message.create!(booking: booking, sender: owner, body: "Hello! Looking forward to welcoming you.")
  MessageMailer.with(message: message).new_message.deliver_now

  BookingMailer.with(booking: booking).review_request.deliver_now

  puts "Done. If you're using delivery_method=:test, check ActionMailer::Base.deliveries."
end
