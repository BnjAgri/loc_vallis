class UserMailer < ApplicationMailer
  def welcome
    @user = params.fetch(:user)

    mail(to: @user.email, subject: "Welcome to Loc Vallis")
  end
end
