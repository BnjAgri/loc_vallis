class MessageMailer < ApplicationMailer
  def new_message
    @message = params.fetch(:message)
    @booking = @message.booking
    set_booking_brand!
    @booking_url = booking_url_for(@booking)

    mail(to: recipient_email, subject: brand_subject("Nouveau message concernant la réservation ##{@booking.id}"))
  end

  private

  def recipient_email
    override = params[:override_to].to_s.strip.presence
    return override if override

    if @message.sender.is_a?(User)
      @booking.room.owner.email
    else
      @booking.user.email
    end
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
