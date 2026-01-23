class BookingMailer < ApplicationMailer
  def requested
    @booking = params.fetch(:booking)
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: "Booking requested")
  end

  def approved
    @booking = params.fetch(:booking)
    @deadline = @booking.payment_expires_at
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: "Booking approved — payment required")
  end

  def declined
    @booking = params.fetch(:booking)
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: "Booking declined")
  end

  def confirmed
    @booking = params.fetch(:booking)
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: "Booking confirmed")
  end

  def canceled
    @booking = params.fetch(:booking)
    @canceled_by = params[:canceled_by]
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: "Booking canceled")
  end

  def expired
    @booking = params.fetch(:booking)
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: "Booking expired")
  end

  def refunded
    @booking = params.fetch(:booking)
    @booking_url = booking_url_for(@booking)
    mail(to: recipient_emails_for_booking, subject: "Booking refunded")
  end

  private

  def recipient_emails_for_booking
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
end
