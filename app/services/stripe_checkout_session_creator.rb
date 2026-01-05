# frozen_string_literal: true

class StripeCheckoutSessionCreator
  def self.call(booking:)
    new(booking:).call
  end

  def initialize(booking:)
    @booking = booking
  end

  def call
    raise StandardError, "Booking must be approved for payment" unless booking.payment_window_open?

    session = Stripe::Checkout::Session.create(
      mode: "payment",
      client_reference_id: booking.id,
      metadata: {
        booking_id: booking.id
      },
      line_items: [
        {
          quantity: booking.nights,
          price_data: {
            currency: booking.currency.downcase,
            unit_amount: unit_amount_cents,
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

  def unit_amount_cents
    # Booking total is authoritative; compute per-night for checkout line item.
    # (Stripe requires unit_amount; we represent it as nightly price.)
    (booking.total_price_cents / booking.nights)
  end

  def base_url
    ENV.fetch("APP_BASE_URL", "http://localhost:3000")
  end

  def success_url
    "#{base_url}/bookings/#{booking.id}?checkout=success"
  end

  def cancel_url
    "#{base_url}/bookings/#{booking.id}?checkout=cancel"
  end
end
