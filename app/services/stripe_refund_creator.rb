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
  def self.call(booking:)
    new(booking:).call
  end

  def initialize(booking:)
    @booking = booking
  end

  def call
    raise StandardError, "Only confirmed_paid bookings can be refunded" unless booking.status == "confirmed_paid"
    raise StandardError, "Missing Stripe payment_intent" if booking.stripe_payment_intent_id.blank?
    raise StandardError, "Already refunded" if booking.stripe_refund_id.present? || booking.status == "refunded"

    refund = Stripe::Refund.create(payment_intent: booking.stripe_payment_intent_id)

    booking.update!(
      status: "refunded",
      stripe_refund_id: refund.id,
      refunded_at: Time.current
    )

    refund
  end

  private

  attr_reader :booking
end
