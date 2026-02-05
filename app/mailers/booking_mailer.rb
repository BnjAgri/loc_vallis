class BookingMailer < ApplicationMailer
  def requested
    @booking = params.fetch(:booking)
    set_booking_brand!
    @booking_url = booking_url_for(@booking)
    mail(to: @booking.user.email, subject: brand_subject("Demande de réservation envoyée"))
  end

  def requested_owner
    @booking = params.fetch(:booking)
    set_booking_brand!
    @admin_booking_url = admin_booking_url_for(@booking)
    mail(to: @booking.room.owner.email, subject: brand_subject("Nouvelle demande de réservation"))
  end

  def approved
    @booking = params.fetch(:booking)
    set_booking_brand!
    @deadline = @booking.payment_expires_at
    @deadline_formatted = @deadline.present? ? I18n.l(@deadline, format: :long) : nil
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: brand_subject("Réservation acceptée — paiement requis"))
  end

  def declined
    @booking = params.fetch(:booking)
    set_booking_brand!
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: brand_subject("Réservation refusée"))
  end

  def confirmed
    @booking = params.fetch(:booking)
    set_booking_brand!
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: brand_subject("Réservation confirmée"))
  end

  def canceled
    @booking = params.fetch(:booking)
    set_booking_brand!
    @canceled_by = params[:canceled_by]
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: brand_subject("Réservation annulée"))
  end

  def expired
    @booking = params.fetch(:booking)
    set_booking_brand!
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: brand_subject("Réservation expirée"))
  end

  def refunded
    @booking = params.fetch(:booking)
    set_booking_brand!
    @booking_url = booking_url_for(@booking)
    @cgv_url = cgv_url_for
    mail(to: recipient_emails_for_booking, subject: brand_subject("Réservation remboursée"))
  end

  def review_request
    @booking = params.fetch(:booking)
    set_booking_brand!
    @booking_url = booking_url_for(@booking)

    mail(to: @booking.user.email, subject: brand_subject("Comment s’est passé votre séjour ?"))
  end

  private

  def recipient_emails_for_booking
    override = params[:override_to].to_s.strip.presence
    return [override] if override

    [@booking.user.email, @booking.room.owner.email]
  end

  def admin_booking_url_for(booking)
    base = ENV.fetch("APP_BASE_URL", "http://localhost:3000")
    uri = URI.parse(base)

    admin_booking_url(
      id: booking,
      host: uri.host,
      protocol: uri.scheme,
      port: uri.port
    )
  end

  def booking_url_for(booking)
    base = ENV.fetch("APP_BASE_URL", "http://localhost:3000")
    uri = URI.parse(base)

    booking_url(
      id: booking,
      host: uri.host,
      protocol: uri.scheme,
      port: uri.port
    )
  end

  def cgv_url_for
    base = ENV.fetch("APP_BASE_URL", "http://localhost:3000")
    uri = URI.parse(base)

    cgv_url(
      host: uri.host,
      protocol: uri.scheme,
      port: uri.port
    )
  end

  def set_booking_brand!
    owner = @booking&.room&.owner
    brand_name = owner&.guesthouse_name.to_s.strip.presence || owner&.display_name
    set_email_brand(name: (brand_name || "Loc Vallis"), url: default_email_brand_url)
  end
end
