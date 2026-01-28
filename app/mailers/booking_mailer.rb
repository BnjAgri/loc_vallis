class BookingMailer < ApplicationMailer
  def requested
    @booking = params.fetch(:booking)
    set_booking_brand!
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: brand_subject("Booking requested"))
  end

  def approved
    @booking = params.fetch(:booking)
    set_booking_brand!
    @deadline = @booking.payment_expires_at
    @deadline_formatted = @deadline.present? ? I18n.l(@deadline, format: :long) : nil
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: brand_subject("Booking approved — payment required"))
  end

  def declined
    @booking = params.fetch(:booking)
    set_booking_brand!
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: brand_subject("Booking declined"))
  end

  def confirmed
    @booking = params.fetch(:booking)
    set_booking_brand!
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: brand_subject("Booking confirmed"))
  end

  def canceled
    @booking = params.fetch(:booking)
    set_booking_brand!
    @canceled_by = params[:canceled_by]
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: brand_subject("Booking canceled"))
  end

  def expired
    @booking = params.fetch(:booking)
    set_booking_brand!
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: brand_subject("Booking expired"))
  end

  def refunded
    @booking = params.fetch(:booking)
    set_booking_brand!
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: brand_subject("Booking refunded"))
  end

  def review_request
    @booking = params.fetch(:booking)
    set_booking_brand!
    @booking_url = booking_url_for(@booking)

    mail(to: @booking.user.email, subject: brand_subject("How was your stay?"))
  end

  private

  def recipient_emails_for_booking
    override = params[:override_to].to_s.strip.presence
    return [override] if override

    [@booking.user.email, @booking.room.owner.email]
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

  def set_booking_brand!
    owner = @booking&.room&.owner
    brand_name = owner&.guesthouse_name.to_s.strip.presence || owner&.display_name
    set_email_brand(name: (brand_name || "Loc Vallis"), url: default_email_brand_url)
  end
end
