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
  validate :within_opening_period_and_available, on: :create

  before_validation :default_status, on: :create
  before_validation :populate_pricing_from_quote, on: :create

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

  def mark_refunded!(refund_id:)
    raise ArgumentError, "refund_id required" if refund_id.blank?

    update!(status: "refunded", stripe_refund_id: refund_id, refunded_at: Time.current)
  end

  def approve!(by:)
    raise ArgumentError, "Only an owner can approve" unless by.is_a?(Owner)
    raise StandardError, "Only requested bookings can be approved" unless requested?

    now = Time.current
    update!(
      status: "approved_pending_payment",
      approved_at: now,
      payment_expires_at: now + 48.hours
    )
  end

  def decline!(by:)
    raise ArgumentError, "Only an owner can decline" unless by.is_a?(Owner)
    raise StandardError, "Only requested bookings can be declined" unless requested?

    update!(status: "declined")
  end

  def cancel!(by:)
    raise ArgumentError, "Actor required" if by.nil?

    allowed = %w[requested approved_pending_payment confirmed_paid].include?(status)
    return false unless allowed

    update!(status: "canceled")
  end

  def expire_if_needed!
    return false unless approved_pending_payment?
    return false if payment_expires_at.blank?
    return false if Time.current < payment_expires_at

    update!(status: "expired")
    BookingMailer.with(booking: self).expired.deliver_later
  end

  def self.expire_overdue!
    where(status: "approved_pending_payment")
      .where("payment_expires_at IS NOT NULL AND payment_expires_at < ?", Time.current)
      .find_each(&:expire_if_needed!)
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

  def quote
    return nil if room.nil? || start_date.blank? || end_date.blank?

    BookingQuote.call(room:, start_date:, end_date:)
  end

  def within_opening_period_and_available
    result = quote
    return if result.nil?

    errors.add(:base, result.error) unless result.ok?
  end

  def populate_pricing_from_quote
    return if total_price_cents.present? && currency.present?

    result = quote
    return if result.nil? || !result.ok?

    self.currency ||= result.currency
    self.total_price_cents ||= result.total_price_cents
  end
end
