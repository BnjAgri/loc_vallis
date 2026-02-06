## OpeningPeriod
# Période d'ouverture tarifée d'une `Room`.
#
# Règles métier :
# - `end_date` doit être strictement après `start_date`.
# - Deux périodes d'une même room ne doivent pas se chevaucher.
#
# `BookingQuote` exige qu'une demande de booking soit entièrement incluse dans une seule période.
class OpeningPeriod < ApplicationRecord
  belongs_to :room

  attr_accessor :nightly_price_euros

  before_validation :populate_nightly_price_cents_from_euros

  validates :start_date, :end_date, :nightly_price_cents, :currency, presence: true
  validates :nightly_price_cents, numericality: { only_integer: true, greater_than: 0 }
  validate :end_date_after_start_date
  validate :no_overlapping_periods

  private

  def populate_nightly_price_cents_from_euros
    return if nightly_price_euros.blank?

    raw = nightly_price_euros.to_s.strip.tr(",", ".")

    euros = begin
      BigDecimal(raw)
    rescue ArgumentError
      nil
    end

    if euros.nil?
      errors.add(:nightly_price_euros, "is invalid")
      return
    end

    self.nightly_price_cents = (euros * 100).round(0).to_i
  end

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date > start_date

    errors.add(:end_date, :after_start_date)
  end

  def no_overlapping_periods
    return if room_id.blank? || start_date.blank? || end_date.blank?

    overlap = OpeningPeriod
      .where(room_id: room_id)
      .where.not(id: id)
      .where("start_date < ? AND end_date > ?", end_date, start_date)
      .exists?

    errors.add(:base, "Opening period overlaps an existing period") if overlap
  end
end
