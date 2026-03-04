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

    booking_id = session.metadata&.booking_id || session.metadata&.[]("booking_id")

    booking = booking_id.present? ? Booking.find_by(id: booking_id) : Booking.find_by(stripe_checkout_session_id: session.id)

    return if booking.nil?

    booking.update!(stripe_checkout_session_id: session.id) if booking.stripe_checkout_session_id.blank?
    booking.update!(stripe_payment_intent_id: session.payment_intent) if session.payment_intent.present? && booking.stripe_payment_intent_id.blank?

    return unless booking.status == "approved_pending_payment"
    return if booking.payment_expires_at.present? && Time.current >= booking.payment_expires_at

    booking.update!(status: "confirmed_paid")
    BookingMailer.with(booking: booking).confirmed.deliver_later
  end

  def handle_payment_intent_succeeded(payment_intent)
    payment_intent_id = payment_intent.respond_to?(:id) ? payment_intent.id : nil
    return if payment_intent_id.blank?

    booking = Booking.find_by(stripe_payment_intent_id: payment_intent_id)
    return if booking.nil?

    return unless booking.status == "approved_pending_payment"
    return if booking.payment_expires_at.present? && Time.current >= booking.payment_expires_at

    booking.update!(status: "confirmed_paid")
    BookingMailer.with(booking: booking).confirmed.deliver_later
  end

  def handle_refund_updated(refund)
    booking = Booking.find_by(stripe_refund_id: refund.id)
    return if booking.nil?

    # We set status/refunded_at on refund creation; keep it idempotent.
    booking.update!(status: "refunded") unless booking.refunded?
    booking.update!(refunded_at: Time.current) if booking.refunded_at.blank?
  end
end
