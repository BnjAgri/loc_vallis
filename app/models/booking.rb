class Booking < ApplicationRecord
  belongs_to :room
  belongs_to :user

  has_many :messages, dependent: :destroy

  STATUSES = %w[
    requested
    approved_pending_payment
    confirmed_paid
    declined
    canceled
    expired
    refunded
  ].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :start_date, :end_date, presence: true
  validates :total_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :currency, presence: true, if: -> { total_price_cents.present? }

  validates :stripe_checkout_session_id, uniqueness: true, allow_nil: true
  validates :stripe_payment_intent_id, uniqueness: true, allow_nil: true
  validates :stripe_refund_id, uniqueness: true, allow_nil: true

  validate :end_date_after_start_date
  validate :fully_within_one_opening_period, on: :create
  validate :no_overlapping_reserved_bookings, on: :create

  before_validation :default_status, on: :create
  before_validation :populate_pricing_from_opening_period, on: :create

  def nights
    return 0 if start_date.blank? || end_date.blank?

    (end_date - start_date).to_i
  end

  def payment_window_open?
    approved_pending_payment? && payment_expires_at.present? && Time.current < payment_expires_at
  end

  def requested?
    status == "requested"
  end

  def approved_pending_payment?
    status == "approved_pending_payment"
  end

  def confirmed_paid?
    status == "confirmed_paid"
  end

  def refunded?
    status == "refunded"
  end

  private

  def default_status
    self.status ||= "requested"
  end

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date > start_date

    errors.add(:end_date, "must be after start_date")
  end

  def opening_period_covering_range
    return nil if room_id.blank? || start_date.blank? || end_date.blank?

    OpeningPeriod
      .where(room_id: room_id)
      .where("start_date <= ? AND end_date >= ?", start_date, end_date)
      .order(:start_date)
      .first
  end

  def fully_within_one_opening_period
    return if start_date.blank? || end_date.blank?

    errors.add(:base, "Dates must be fully inside one opening period") if opening_period_covering_range.nil?
  end

  def populate_pricing_from_opening_period
    return if start_date.blank? || end_date.blank? || room_id.blank?
    return if total_price_cents.present? && currency.present?

    period = opening_period_covering_range
    return if period.nil?

    self.currency ||= period.currency
    self.total_price_cents ||= period.nightly_price_cents * nights
  end

  def no_overlapping_reserved_bookings
    return if room_id.blank? || start_date.blank? || end_date.blank?

    overlap = Booking
      .where(room_id: room_id)
      .where(status: %w[approved_pending_payment confirmed_paid])
      .where("start_date < ? AND end_date > ?", end_date, start_date)
      .exists?

    errors.add(:base, "Dates overlap an existing booking") if overlap
  end
end
