class ApplicationMailer < ActionMailer::Base
  default from: (ENV["MAIL_FROM"].presence || "no-reply@loc-vallis.example")
  layout "mailer"
end
