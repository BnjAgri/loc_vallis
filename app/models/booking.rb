## Booking
# Représente une demande de réservation d'un `User` sur une `Room`.
#
# La booking stocke des dates (start_date/end_date), un statut et (après création)
# un prix total en cents + devise. Le prix est calculé à la création via `BookingQuote`
# puis persisté pour éviter toute ambiguïté en cas de changement ultérieur de tarifs.
#
# Statuts (machine d'état “simple”, basée sur une string) :
# - requested -> approved_pending_payment -> confirmed_paid
# - requested -> declined
# - requested|approved_pending_payment -> canceled
# - approved_pending_payment -> expired (si fenêtre de paiement dépassée)
# - confirmed_paid -> refunded
#
# Intégration Stripe :
# - `stripe_checkout_session_id` et `stripe_payment_intent_id` servent à réconcilier les paiements.
# - `stripe_refund_id` sert à réconcilier les remboursements.
class Booking < ApplicationRecord
  belongs_to :room
  belongs_to :user

  attr_accessor :accepts_terms

  has_one :review, dependent: :destroy

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

  RESERVED_STATUSES = %w[approved_pending_payment confirmed_paid].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :start_date, :end_date, presence: true
  validates :total_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :currency, presence: true, if: -> { total_price_cents.present? }

  before_save :set_status_changed_at

  validates :stripe_checkout_session_id, uniqueness: true, allow_nil: true
  validates :stripe_payment_intent_id, uniqueness: true, allow_nil: true
  validates :stripe_refund_id, uniqueness: true, allow_nil: true

  validate :validate_selected_optional_services, if: :validate_selected_optional_services?

  validate :end_date_after_start_date
  validate :within_opening_period_and_available, on: :create
  validate :no_overlap_with_other_reserved_bookings, if: :reserved_status?

  validates :accepts_terms, acceptance: { accept: ["1", true] }, on: :user_request

  before_validation :default_status, on: :create
  before_validation :populate_pricing_from_quote, if: -> { total_price_cents.blank? || currency.blank? }

  def nights
    return 0 if start_date.blank? || end_date.blank?

    (end_date - start_date).to_i
  end

  def selected_optional_services_total_cents
    Array(selected_optional_services).sum do |entry|
      next 0 unless entry.is_a?(Hash)

      cents = entry["price_cents"] || entry[:price_cents]
      cents.is_a?(Integer) ? cents : cents.to_i
    end
  end

  def mark_owner_read!
    update!(owner_last_read_at: Time.current)
  end

  def mark_user_read!
    update!(user_last_read_at: Time.current)
  end

  def unread_messages_for_owner_count
    threshold = owner_last_read_at || Time.at(0)
    messages.where(sender_type: "User").where("created_at > ?", threshold).count
  end

  def unread_messages_for_user_count
    threshold = user_last_read_at || Time.at(0)
    messages.where(sender_type: "Owner").where("created_at > ?", threshold).count
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

  def reserved_status?
    RESERVED_STATUSES.include?(status)
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

    allowed = %w[requested approved_pending_payment].include?(status)
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
      .find_each do |booking|
        begin
          booking.expire_if_needed!
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error("Booking##{booking.id} expire failed: #{e.message}")
        end
      end
  end

  def self.cancel_overdue_requested!(as_of: Date.current)
    where(status: "requested")
      .where("start_date < ?", as_of)
      .find_each do |booking|
        begin
          booking.update!(status: "canceled")
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error("Booking##{booking.id} auto-cancel failed: #{e.message}")
        end
      end
  end

  def self.send_review_requests_after_stay!(as_of: Date.current)
    target_end_date = as_of - 1.day

    left_outer_joins(:review)
      .where(status: %w[confirmed_paid refunded])
      .where(end_date: target_end_date)
      .where(review_request_sent_at: nil)
      .where(reviews: { id: nil })
      .includes(:user, room: :owner)
      .find_each do |booking|
        begin
          booking.enqueue_review_request_email!
        rescue StandardError => e
          Rails.logger.error("Booking##{booking.id} review_request enqueue failed: #{e.class}: #{e.message}")
        end
      end
  end

  def enqueue_review_request_email!
    return false if review&.persisted?

    now = Time.current
    updated = self.class
      .where(id: id, review_request_sent_at: nil)
      .update_all(review_request_sent_at: now, updated_at: now)

    return false unless updated == 1

    BookingMailer.with(booking: self).review_request.deliver_later
    true
  end

  private

  def default_status
    self.status ||= "requested"
  end

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date > start_date

    errors.add(:end_date, :after_start_date)
  end

  def quote
    return nil if room.nil? || start_date.blank? || end_date.blank?

    BookingQuote.call(
      room:,
      start_date:,
      end_date:,
      optional_services_total_cents: selected_optional_services_total_cents
    )
  end

  def within_opening_period_and_available
    result = quote
    return if result.nil?

    errors.add(:base, result.error) unless result.ok?
  end

  def no_overlap_with_other_reserved_bookings
    return if room_id.blank? || start_date.blank? || end_date.blank?

    overlap_exists = Booking
      .where(room_id: room_id)
      .where(status: RESERVED_STATUSES)
      .where.not(id: id)
      .where("start_date < ? AND end_date > ?", end_date, start_date)
      .exists?

    errors.add(:base, :dates_overlap_existing_booking) if overlap_exists
  end

  def populate_pricing_from_quote
    return if total_price_cents.present? && currency.present?

    result = quote
    return if result.nil? || !result.ok?

    self.currency ||= result.currency
    self.total_price_cents ||= result.total_price_cents
  end

  def validate_selected_optional_services
    services = selected_optional_services
    services = services.values if services.is_a?(Hash)
    services = Array(services)

    if services.size > 5
      errors.add(:selected_optional_services, "maximum 5")
      return
    end

    # Prevent tampering: selected services must match the room's configured services.
    allowed = Array(room&.optional_services)
    allowed_by_name = allowed.each_with_object({}) do |entry, acc|
      next unless entry.is_a?(Hash)

      name = (entry["name"] || entry[:name]).to_s.strip
      next if name.blank?

      acc[name] = entry
    end

    services.each do |entry|
      next unless entry.is_a?(Hash)

      name = (entry["name"] || entry[:name]).to_s.strip
      price_cents = entry["price_cents"] || entry[:price_cents]
      currency = (entry["currency"] || entry[:currency]).to_s.presence || "EUR"

      if name.blank?
        errors.add(:selected_optional_services, "nom manquant")
        next
      end

      unless price_cents.is_a?(Integer) && price_cents >= 0
        errors.add(:selected_optional_services, "prix invalide")
        next
      end

      allowed_entry = allowed_by_name[name]
      if allowed_entry.nil?
        errors.add(:selected_optional_services, "service inconnu")
        next
      end

      allowed_price = allowed_entry["price_cents"] || allowed_entry[:price_cents]
      if allowed_price.to_i != price_cents
        errors.add(:selected_optional_services, "prix invalide")
      end

      allowed_currency = (allowed_entry["currency"] || allowed_entry[:currency]).to_s.presence || "EUR"
      if allowed_currency.to_s.upcase != currency.to_s.upcase
        errors.add(:selected_optional_services, "devise invalide")
      end
    end
  end

  def validate_selected_optional_services?
    new_record? || will_save_change_to_selected_optional_services? || will_save_change_to_room_id?
  end

  def set_status_changed_at
    return unless will_save_change_to_status? || status_changed_at.blank?

    self.status_changed_at = Time.current
  end
end
