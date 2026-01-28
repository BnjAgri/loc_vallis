class UserMailer < ApplicationMailer
  def welcome
    @user = params.fetch(:user)

    set_email_brand(name: "Loc Vallis", url: default_email_brand_url)

    mail(to: @user.email, subject: brand_subject("Welcome"))
  end
end
