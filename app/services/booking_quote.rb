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
    return error_result("Room is required") if room.nil?
    return error_result("Start date is required") if start_date.blank?
    return error_result("End date is required") if end_date.blank?
    return error_result("End date must be after start date") unless end_date > start_date

    period = opening_period_covering_range
    return error_result("Dates must be fully inside one opening period") if period.nil?

    return error_result("Dates overlap an existing booking") if overlaps_reserved_booking?

    nights = (end_date - start_date).to_i
    base_total = period.nightly_price_cents * nights
    total = base_total + optional_services_total_cents

    Result.new(
      ok?: true,
      opening_period: period,
      nights:,
      nightly_price_cents: period.nightly_price_cents,
      optional_services_total_cents:,
      currency: period.currency,
      total_price_cents: total,
      error: nil
    )
  end

  private

  attr_reader :room, :start_date, :end_date
  attr_reader :optional_services_total_cents

  def error_result(message)
    Result.new(
      ok?: false,
      opening_period: nil,
      nights: 0,
      nightly_price_cents: nil,
      optional_services_total_cents: 0,
      currency: nil,
      total_price_cents: nil,
      error: message
    )
  end

  def opening_period_covering_range
    OpeningPeriod
      .where(room_id: room.id)
      .where("start_date <= ? AND end_date >= ?", start_date, end_date)
      .order(:start_date)
      .first
  end

  def overlaps_reserved_booking?
    Booking
      .where(room_id: room.id)
      .where(status: Booking::RESERVED_STATUSES)
      .where("start_date < ? AND end_date > ?", end_date, start_date)
      .exists?
  end
end
