# Shared data builders for Action Mailer previews.
#
# Previews run in development by default. We keep record creation idempotent
# (find-or-create) so refreshing previews doesn't generate endless data.
module PreviewData
  module_function

  def owner
    Owner.find_or_create_by!(email: "preview-owner@locv.test") do |record|
      record.password = "password123"
      record.password_confirmation = "password123"
      record.first_name = "Preview"
      record.last_name = "Owner"
      record.guesthouse_name = "Loc Vallis"
    end
  end

  def user
    User.find_or_create_by!(email: "preview-user@locv.test") do |record|
      record.password = "password123"
      record.password_confirmation = "password123"
      record.first_name = "Preview"
      record.last_name = "Traveler"
    end
  end

  def room
    # Mailer previews must never break when the app hits its MVP constraint (max rooms).
    any_room = Room.unscoped.order(:created_at).first
    return any_room if any_room

    preview_owner = owner

    existing = Room.unscoped.find_by(owner: preview_owner, name: "Chambre Preview")
    return existing if existing

    preview_room = Room.new(
      owner: preview_owner,
      name: "Chambre Preview",
      capacity: 2,
      description: "Une chambre de démonstration pour prévisualiser les emails."
    )
    preview_room.save!(validate: false)
    preview_room
  end

  def opening_period
    existing = OpeningPeriod.where(room: room).order(:start_date).first
    return existing if existing

    today = Date.current

    OpeningPeriod.create!(
      room: room,
      start_date: today + 10,
      end_date: today + 20,
      nightly_price_cents: 12_500,
      currency: "EUR"
    )
  end

  def booking(status: "requested")
    opening_period

    period = opening_period
    start_date, end_date = pick_booking_dates(room: room, opening_period: period)

    record = Booking.find_or_create_by!(
      room: room,
      user: user,
      start_date: start_date,
      end_date: end_date
    )

    # Ensure pricing is present (some templates display totals).
    record.update!(currency: "EUR", total_price_cents: (3 * 12_500)) if record.total_price_cents.blank?

    attrs = { status: status }
    now = Time.current

    case status
    when "approved_pending_payment"
      attrs[:approved_at] = now
      attrs[:payment_expires_at] = now + 48.hours
    when "confirmed_paid"
      attrs[:approved_at] = record.approved_at || (now - 2.days)
      attrs[:payment_expires_at] = record.payment_expires_at || (now - 1.day)
    when "canceled"
    when "expired"
      attrs[:approved_at] = record.approved_at || (now - 3.days)
      attrs[:payment_expires_at] = record.payment_expires_at || (now - 1.hour)
    when "refunded"
      attrs[:refunded_at] = record.refunded_at || now
      attrs[:stripe_refund_id] = record.stripe_refund_id.presence || "re_preview_123"
    end

    record.update!(attrs)
    record
  end

  def message(sender: user, body: "Bonjour, est-ce que l'arrivée tardive est possible ?")
    booking_record = booking(status: "requested")

    Message.create!(
      booking: booking_record,
      sender: sender,
      body: body
    )
  end

  def pick_booking_dates(room:, opening_period:)
    period_start = opening_period.start_date
    period_end = opening_period.end_date

    raise ArgumentError, "OpeningPeriod has invalid dates" if period_start.blank? || period_end.blank? || period_end <= period_start

    reserved_ranges = Booking
      .where(room: room, status: Booking::RESERVED_STATUSES)
      .pluck(:start_date, :end_date)

    # Find a 2-night slot inside the opening period that doesn't overlap reserved bookings.
    latest_start = period_end - 2.days

    candidate = period_start
    while candidate <= latest_start
      candidate_end = candidate + 2.days

      overlaps_reserved = reserved_ranges.any? { |(s, e)| s < candidate_end && e > candidate }
      return [candidate, candidate_end] unless overlaps_reserved

      candidate += 1.day
    end

    # If everything is booked (rare for previews), fall back to the earliest possible 1-night stay.
    latest_start = period_end - 1.day
    candidate = period_start
    while candidate <= latest_start
      candidate_end = candidate + 1.day
      overlaps_reserved = reserved_ranges.any? { |(s, e)| s < candidate_end && e > candidate }
      return [candidate, candidate_end] unless overlaps_reserved

      candidate += 1.day
    end

    # Absolute fallback: return any valid dates inside the period.
    [period_start, period_start + 1.day]
  end
end
