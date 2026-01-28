class ApplicationMailer < ActionMailer::Base
  default from: (ENV["MAIL_FROM"].presence || "no-reply@loc-vallis.example")
  layout "mailer"

  protected

  def default_email_brand_url
    ENV.fetch("APP_BASE_URL", "http://localhost:3000")
  end

  def set_email_brand(name:, url: nil)
    @email_brand_name = name.to_s.strip.presence
    @email_brand_url = url.to_s.strip.presence
  end

  def brand_subject(subject)
    clean = subject.to_s.strip
    return clean if clean.blank?

    brand = @email_brand_name.to_s.strip.presence
    return clean if brand.blank?

    "#{brand} — #{clean}"
  end
end
