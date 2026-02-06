# frozen_string_literal: true

## OpeningPeriodBlocker
# Retire une plage de dates d'une OpeningPeriod en la raccourcissant ou en la scindant.
#
# Convention dates (cohérente avec Booking / OpeningPeriod) :
# - start_date inclus
# - end_date exclu
#
# Exemples :
# - retirer au début : [start, to) => start = to
# - retirer à la fin  : [from, end) => end = from
# - retirer au milieu : split en [start, from) et [to, end)
class OpeningPeriodBlocker
  def self.call(opening_period:, start_date:, end_date:)
    new(opening_period:, start_date:, end_date:).call
  end

  def initialize(opening_period:, start_date:, end_date:)
    @opening_period = opening_period
    @start_date_raw = start_date
    @end_date_raw = end_date
  end

  def call
    raise ArgumentError, "opening_period required" if opening_period.nil?

    block_start = parse_date!(@start_date_raw, "start_date")
    block_end = parse_date!(@end_date_raw, "end_date")

    raise StandardError, "Invalid date range" unless block_start < block_end

    unless block_start >= opening_period.start_date && block_end <= opening_period.end_date
      raise StandardError, "Block range must be inside the opening period"
    end

    blocking_statuses = Booking::RESERVED_STATUSES + ["requested"]
    has_blocking_booking = opening_period.room.bookings
      .where(status: blocking_statuses)
      .where("start_date < ? AND end_date > ?", block_end, block_start)
      .exists?

    raise StandardError, "Cannot block dates overlapping an existing booking" if has_blocking_booking

    old_start = opening_period.start_date
    old_end = opening_period.end_date

    if block_start == old_start && block_end == old_end
      opening_period.destroy!
      return true
    end

    if block_start == old_start
      opening_period.update!(start_date: block_end)
      return true
    end

    if block_end == old_end
      opening_period.update!(end_date: block_start)
      return true
    end

    OpeningPeriod.transaction do
      opening_period.update!(end_date: block_start)
      OpeningPeriod.create!(
        room: opening_period.room,
        start_date: block_end,
        end_date: old_end,
        nightly_price_cents: opening_period.nightly_price_cents,
        currency: opening_period.currency
      )
    end

    true
  end

  private

  attr_reader :opening_period

  def parse_date!(value, label)
    raw = value.to_s.strip
    raise StandardError, "#{label} is required" if raw.blank?

    Date.iso8601(raw)
  rescue ArgumentError
    raise StandardError, "#{label} is invalid"
  end
end
