class OpeningPeriod < ApplicationRecord
  belongs_to :room

  validates :start_date, :end_date, :nightly_price_cents, :currency, presence: true
  validates :nightly_price_cents, numericality: { only_integer: true, greater_than: 0 }
  validate :end_date_after_start_date
  validate :no_overlapping_periods

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date > start_date

    errors.add(:end_date, "must be after start_date")
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
