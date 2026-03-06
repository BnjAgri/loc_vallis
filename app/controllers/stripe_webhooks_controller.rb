## StripeWebhooksController
# Endpoint de réception des webhooks Stripe.
#
# Contrainte importante : les webhooks doivent être traités de manière **idempotente**
# (Stripe peut renvoyer le même événement).
#
# Vérification : la signature est validée via `STRIPE_WEBHOOK_SECRET`.
class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = request.raw_post
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

    webhook_secret = ENV["STRIPE_WEBHOOK_SECRET"].presence
    if webhook_secret.blank?
      Rails.logger.warn("[Stripe] Missing STRIPE_WEBHOOK_SECRET; cannot verify webhook signature")
      return head :bad_request
    end

    if sig_header.blank?
      Rails.logger.warn("[Stripe] Missing Stripe-Signature header")
      return head :bad_request
    end

    event = Stripe::Webhook.construct_event(
      payload,
      sig_header,
      webhook_secret
    )

    Rails.logger.info("[Stripe] Webhook received: type=#{event.type} id=#{event.id}")

    handle_event(event)

    head :ok
  rescue JSON::ParserError => e
    Rails.logger.warn("[Stripe] Webhook JSON parse error: #{e.message}")
    head :bad_request
  rescue Stripe::SignatureVerificationError => e
    Rails.logger.warn("[Stripe] Webhook signature verification failed: #{e.message}")
    head :bad_request
  end

  private

  def handle_event(event)
    case event.type
    when "checkout.session.completed"
      handle_checkout_completed(event.data.object)
    when "checkout.session.async_payment_succeeded"
      handle_checkout_completed(event.data.object)
    when "checkout.session.async_payment_failed", "checkout.session.expired"
      # Intentionally no state change here; we expire via job/guard.
      nil
    when "payment_intent.succeeded"
      handle_payment_intent_succeeded(event.data.object)
    when "refund.updated"
      handle_refund_updated(event.data.object)
    end
  end

  def handle_checkout_completed(session)
    payment_status = session.respond_to?(:payment_status) ? session.payment_status : nil
    return unless payment_status == "paid"

    booking = find_booking_from_checkout_session(session)
    return if booking.nil?

    StripeBookingConfirmer.call(
      booking: booking,
      stripe_checkout_session_id: session.id,
      stripe_payment_intent_id: session.payment_intent
    )
  end

  def handle_payment_intent_succeeded(payment_intent)
    payment_intent_id = payment_intent.respond_to?(:id) ? payment_intent.id : nil
    return if payment_intent_id.blank?

    booking = Booking.find_by(stripe_payment_intent_id: payment_intent_id)
    return if booking.nil?

    StripeBookingConfirmer.call(
      booking: booking,
      stripe_payment_intent_id: payment_intent_id
    )
  end

  def find_booking_from_checkout_session(session)
    metadata = session.respond_to?(:metadata) ? session.metadata : nil
    booking_id = metadata&.respond_to?(:booking_id) ? metadata.booking_id : nil
    booking_id ||= metadata&.[]("booking_id") if metadata.respond_to?(:[])

    # StripeCheckoutSessionCreator also sets `client_reference_id` to booking.id.
    client_reference_id = session.respond_to?(:client_reference_id) ? session.client_reference_id : nil

    booking = nil
    booking ||= Booking.find_by(id: booking_id) if booking_id.present?
    booking ||= Booking.find_by(id: client_reference_id) if client_reference_id.present?

    session_id = session.respond_to?(:id) ? session.id : nil
    booking ||= Booking.find_by(stripe_checkout_session_id: session_id) if session_id.present?

    payment_intent_id = session.respond_to?(:payment_intent) ? session.payment_intent : nil
    booking ||= Booking.find_by(stripe_payment_intent_id: payment_intent_id) if payment_intent_id.present?

    booking
  end

  def handle_refund_updated(refund)
    booking = Booking.find_by(stripe_refund_id: refund.id)
    return if booking.nil?

    # We set status/refunded_at on refund creation; keep it idempotent.
    booking.update!(status: "refunded") unless booking.refunded?
    booking.update!(refunded_at: Time.current) if booking.refunded_at.blank?
  end
end
