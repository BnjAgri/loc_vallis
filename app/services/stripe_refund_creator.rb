# frozen_string_literal: true

## StripeRefundCreator
# Déclenche un remboursement Stripe pour une `Booking` payée.
#
# Préconditions :
# - booking.status == "confirmed_paid"
# - `stripe_payment_intent_id` présent
# - pas déjà remboursée
#
# Effets de bord :
# - appelle l'API Stripe (création refund)
# - passe la booking à `refunded` et stocke `stripe_refund_id` + `refunded_at`
class StripeRefundCreator
  def self.call(booking:, amount_cents: nil)
    new(booking:, amount_cents:).call
  end

  def initialize(booking:, amount_cents: nil)
    @booking = booking
    @amount_cents = amount_cents
  end

  def call
    raise StandardError, "Stripe is not configured (missing STRIPE_SECRET_KEY)" if Stripe.api_key.blank?
    raise StandardError, "Only confirmed_paid bookings can be refunded" unless booking.status == "confirmed_paid"
    raise StandardError, "Missing Stripe payment_intent" if booking.stripe_payment_intent_id.blank?
    raise StandardError, "Already refunded" if booking.stripe_refund_id.present? || booking.status == "refunded"

    if amount_cents.present?
      raise StandardError, "Invalid refund amount" unless amount_cents.is_a?(Integer)
      raise StandardError, "Invalid refund amount" unless amount_cents.positive?

      max = booking.total_price_cents.to_i
      raise StandardError, "Invalid refund amount" if max <= 0
      raise StandardError, "Refund amount exceeds total" if amount_cents > max
    end

    payload = { payment_intent: booking.stripe_payment_intent_id }
    payload[:amount] = amount_cents if amount_cents.present?

    refund = Stripe::Refund.create(payload)

    booking.update!(
      status: "refunded",
      stripe_refund_id: refund.id,
      refunded_at: Time.current
    )

    refund
  end

  private

  attr_reader :booking

  attr_reader :amount_cents
end
