# frozen_string_literal: true

env_secret_key = ENV["STRIPE_SECRET_KEY"].presence
env_webhook_secret = ENV["STRIPE_WEBHOOK_SECRET"].presence

credentials_secret_key = Rails.application.credentials.dig(:stripe, :secret_key) ||
                         Rails.application.credentials.dig(:stripe_secret_key)

secret_key = env_secret_key.presence || credentials_secret_key

# Common misconfig: people sometimes paste the publishable key (pk_...) into STRIPE_SECRET_KEY
# and the secret key (sk_...) into STRIPE_WEBHOOK_SECRET.
if secret_key&.start_with?("pk_") && env_webhook_secret&.start_with?("sk_")
  Rails.logger.warn(
    "[Stripe] STRIPE_SECRET_KEY looks like a publishable key (pk_...). " \
    "Using STRIPE_WEBHOOK_SECRET as Stripe.api_key (it looks like sk_...). " \
    "Please fix your .env variables."
  ) unless Rails.env.test?

  secret_key = env_webhook_secret
end

if env_webhook_secret.present? && !env_webhook_secret.start_with?("whsec_")
  Rails.logger.warn(
    "[Stripe] STRIPE_WEBHOOK_SECRET should look like whsec_... (Stripe CLI / Dashboard endpoint secret)."
  ) unless Rails.env.test?
end

if secret_key.blank?
  Rails.logger.warn("[Stripe] STRIPE_SECRET_KEY is not set; Stripe API calls will fail") unless Rails.env.test?
elsif secret_key.start_with?("pk_")
  raise "[Stripe] STRIPE_SECRET_KEY must be a secret key (sk_...), not a publishable key (pk_...)"
else
  Stripe.api_key = secret_key
end
