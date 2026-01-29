require_relative "preview_data"

class UserMailerPreview < ActionMailer::Preview
  def welcome
    UserMailer.with(user: PreviewData.user).welcome
  end
end
