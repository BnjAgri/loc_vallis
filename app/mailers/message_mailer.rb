class MessageMailer < ApplicationMailer
  def new_message
    @message = params.fetch(:message)
    @booking = @message.booking
    @booking_url = booking_url_for(@booking)

    mail(to: recipient_email, subject: "New message about booking ##{@booking.id}")
  end

  private

  def recipient_email
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
      booking,
      host: uri.host,
      protocol: uri.scheme,
      port: uri.port
    )
  end
end
