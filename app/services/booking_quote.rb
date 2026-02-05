# frozen_string_literal: true

## BookingQuote
# Calcule un devis de réservation (prix + validations métier) pour une `Room`.
#
# Règles appliquées :
# - start_date/end_date doivent être présentes et cohérentes (end_date > start_date).
# - l'intervalle doit être entièrement couvert par un unique `OpeningPeriod`.
# - l'intervalle ne doit pas chevaucher une booking “réservante” (statuts `RESERVED_STATUSES`).
#
# Retourne un `Result` (struct) avec `ok?` + attributs métier ou une `error` lisible.
class BookingQuote
  Result = Struct.new(
    :ok?,
    :opening_period,
    :opening_periods,
    :pricing_segments,
    :nights,
    :nightly_price_cents,
    :optional_services_total_cents,
    :currency,
    :total_price_cents,
    :error,
    keyword_init: true
  )

  def self.call(room:, start_date:, end_date:, optional_services_total_cents: 0)
    new(room:, start_date:, end_date:, optional_services_total_cents:).call
  end

  def initialize(room:, start_date:, end_date:, optional_services_total_cents: 0)
    @room = room
    @start_date = start_date
    @end_date = end_date
    @optional_services_total_cents = optional_services_total_cents.to_i
  end

  def call
    return error_result(:room_required, default: "Room is required") if room.nil?
    return error_result(:start_date_required, default: "Start date is required") if start_date.blank?
    return error_result(:end_date_required, default: "End date is required") if end_date.blank?
    return error_result(:end_date_after_start_date, default: "End date must be after start date") unless end_date > start_date

    segments = opening_period_segments_covering_range
    return error_result(:dates_not_covered, default: "Dates must be fully covered by opening periods") if segments.nil?

    opening_periods = segments.map { |segment| segment[:opening_period] }.uniq
    currency = opening_periods.first.currency
    unless opening_periods.all? { |p| p.currency == currency }
      return error_result(:currency_mismatch, default: "Opening periods must share the same currency")
    end

    return error_result(:dates_overlap_booking, default: "Dates overlap an existing booking") if overlaps_reserved_booking?

    nights = (end_date - start_date).to_i
    base_total = segments.sum { |segment| segment[:nights] * segment[:nightly_price_cents] }
    total = base_total + optional_services_total_cents

    unique_nightly_prices = segments.map { |segment| segment[:nightly_price_cents] }.uniq
    nightly_price_cents = unique_nightly_prices.size == 1 ? unique_nightly_prices.first : nil

    Result.new(
      ok?: true,
      opening_period: opening_periods.size == 1 ? opening_periods.first : nil,
      opening_periods:,
      pricing_segments: segments,
      nights:,
      nightly_price_cents:,
      optional_services_total_cents:,
      currency:,
      total_price_cents: total,
      error: nil
    )
  end

  private

  attr_reader :room, :start_date, :end_date
  attr_reader :optional_services_total_cents

  def error_result(message, **i18n_options)
    if message.is_a?(Symbol)
      message = I18n.t("booking_quote.errors.#{message}", **i18n_options)
    end

    Result.new(
      ok?: false,
      opening_period: nil,
      opening_periods: [],
      pricing_segments: [],
      nights: 0,
      nightly_price_cents: nil,
      optional_services_total_cents: 0,
      currency: nil,
      total_price_cents: nil,
      error: message
    )
  end

  # Returns an array of pricing segments covering the booking range.
  #
  # Each segment is a Hash:
  #   { opening_period:, start_date:, end_date:, nights:, nightly_price_cents: }
  #
  # Coverage rules:
  # - the full [start_date, end_date) range must be covered
  # - no gaps are allowed
  # - opening periods must be contiguous (next.start_date == previous.end_date)
  def opening_period_segments_covering_range
    periods = OpeningPeriod
      .where(room_id: room.id)
      .where("start_date < ? AND end_date > ?", end_date, start_date)
      .order(:start_date)
      .to_a

    return nil if periods.empty?

    cursor = start_date
    segments = []
    first_currency = nil

    while cursor < end_date
      period = periods.find { |p| p.start_date <= cursor && p.end_date > cursor }
      return nil if period.nil?

      first_currency ||= period.currency
      return nil if period.currency != first_currency

      segment_end = [period.end_date, end_date].min
      return nil unless segment_end > cursor

      segments << {
        opening_period: period,
        start_date: cursor,
        end_date: segment_end,
        nights: (segment_end - cursor).to_i,
        nightly_price_cents: period.nightly_price_cents
      }

      cursor = segment_end
      break if cursor >= end_date

      # Enforce contiguity (no gaps) between periods.
      next_period = periods.find { |p| p.start_date <= cursor && p.end_date > cursor }
      return nil if next_period.nil?
      return nil unless next_period.start_date == cursor
    end

    segments
  end

  def overlaps_reserved_booking?
    Booking
      .where(room_id: room.id)
      .where(status: Booking::RESERVED_STATUSES)
      .where("start_date < ? AND end_date > ?", end_date, start_date)
      .exists?
  end
end
