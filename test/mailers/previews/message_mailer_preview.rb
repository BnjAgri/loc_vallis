require_relative "preview_data"

class MessageMailerPreview < ActionMailer::Preview
  def new_message_from_user
    message = PreviewData.message(sender: PreviewData.user, body: "Bonjour, peut-on arriver vers 22h ?")
    MessageMailer.with(message: message).new_message
  end

  def new_message_from_owner
    message = PreviewData.message(sender: PreviewData.owner, body: "Oui, aucun problème. Pensez à me prévenir 30 minutes avant.")
    MessageMailer.with(message: message).new_message
  end
end
