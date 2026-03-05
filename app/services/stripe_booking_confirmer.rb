# frozen_string_literal: true

## StripeBookingConfirmer
# Confirme une `Booking` après un paiement Stripe.
#
# Objectifs :
# - Idempotent (Stripe peut rejouer des événements, et l'utilisateur peut recharger la page de succès)
# - Sûr (ne confirme que si la booking est en `approved_pending_payment` et dans la fenêtre de paiement)
# - Réconcilie les IDs Stripe (checkout_session_id / payment_intent_id) quand ils sont connus.
class StripeBookingConfirmer
  def self.call(booking:, stripe_checkout_session_id: nil, stripe_payment_intent_id: nil)
    new(booking:, stripe_checkout_session_id:, stripe_payment_intent_id:).call
  end

  def initialize(booking:, stripe_checkout_session_id:, stripe_payment_intent_id:)
    @booking = booking
    @stripe_checkout_session_id = stripe_checkout_session_id
    @stripe_payment_intent_id = stripe_payment_intent_id
  end

  def call
    confirmed = false

    booking.with_lock do
      booking.reload

      reconcile_stripe_ids!

      return false unless booking.status == "approved_pending_payment"
      return false if booking.payment_expires_at.present? && Time.current >= booking.payment_expires_at

      booking.update!(status: "confirmed_paid")
      confirmed = true
    end

    BookingMailer.with(booking: booking).confirmed.deliver_later if confirmed

    confirmed
  end

  private

  attr_reader :booking, :stripe_checkout_session_id, :stripe_payment_intent_id

  def reconcile_stripe_ids!
    updates = {}

    if stripe_checkout_session_id.present? && booking.stripe_checkout_session_id.blank?
      updates[:stripe_checkout_session_id] = stripe_checkout_session_id
    end

    if stripe_payment_intent_id.present? && booking.stripe_payment_intent_id.blank?
      updates[:stripe_payment_intent_id] = stripe_payment_intent_id
    end

    booking.update!(updates) if updates.any?
  end
end
