class MessagesController < ApplicationController
  def create
    authenticate_actor!

    booking = Booking.find(params[:booking_id])
    authorize booking

    message = booking.messages.build(message_params)
    message.sender = current_owner || current_user
    authorize message

    if message.save
      MessageMailer.with(message:).new_message.deliver_later
      redirect_to booking_path(booking)
    else
      redirect_to booking_path(booking), alert: "Message could not be sent."
    end
  end

  private

  def authenticate_actor!
    return if current_owner.present? || current_user.present?

    redirect_to root_path, alert: "Please sign in first."
  end

  def message_params
    params.require(:message).permit(:body)
  end
end
