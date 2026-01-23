# frozen_string_literal: true

## StripeCheckoutSessionCreator
# Crée une Stripe Checkout Session pour une `Booking` déjà approuvée.
#
# Précondition : `booking.payment_window_open?` doit être vrai.
# Effets de bord :
# - appelle l'API Stripe (création de session)
# - persist `stripe_checkout_session_id` et `stripe_payment_intent_id` sur la booking
#
# Note : Stripe nécessite un `unit_amount` (prix unitaire). Comme le total de la booking
# peut inclure des services optionnels “one-shot”, on facture le total en une seule ligne.
class StripeCheckoutSessionCreator
  def self.call(booking:, success_url: nil, cancel_url: nil)
    new(booking:, success_url:, cancel_url:).call
  end

  def initialize(booking:, success_url:, cancel_url:)
    @booking = booking
    @explicit_success_url = success_url
    @explicit_cancel_url = cancel_url
  end

  def call
    raise StandardError, "Stripe is not configured (missing STRIPE_SECRET_KEY)" if Stripe.api_key.blank?
    raise StandardError, "Booking must be approved for payment" unless booking.payment_window_open?

    session = Stripe::Checkout::Session.create(
      mode: "payment",
      client_reference_id: booking.id,
      metadata: {
        booking_id: booking.id
      },
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency: booking.currency.downcase,
            unit_amount: booking.total_price_cents,
            product_data: {
              name: "Stay (#{booking.room.name})"
            }
          }
        }
      ],
      success_url: success_url,
      cancel_url: cancel_url
    )

    booking.update!(
      stripe_checkout_session_id: session.id,
      stripe_payment_intent_id: session.payment_intent
    )

    session
  end

  private

  attr_reader :booking

  def base_url
    ENV.fetch("APP_BASE_URL", "http://localhost:3000")
  end

  def success_url
    return @explicit_success_url if @explicit_success_url.present?

    "#{base_url}/bookings/#{booking.id}?checkout=success"
  end

  def cancel_url
    return @explicit_cancel_url if @explicit_cancel_url.present?

    "#{base_url}/bookings/#{booking.id}?checkout=cancel"
  end
end
