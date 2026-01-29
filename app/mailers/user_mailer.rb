class UserMailer < ApplicationMailer
  def welcome
    @user = params.fetch(:user)
    @login_identifier = @user.email

    base = ENV.fetch("APP_BASE_URL", "http://localhost:3000")
    uri = URI.parse(base)

    @login_url = login_url(
      host: uri.host,
      protocol: uri.scheme,
      port: uri.port,
      email: @login_identifier
    )

    set_email_brand(name: "Loc Vallis", url: default_email_brand_url)

    mail(to: @user.email, subject: brand_subject("Bienvenue"))
  end
end
