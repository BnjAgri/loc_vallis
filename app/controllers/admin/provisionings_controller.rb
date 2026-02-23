# frozen_string_literal: true

require "shellwords"

module Admin
  class ProvisioningsController < ApplicationController
    before_action :authenticate_owner!
    before_action :ensure_provisioning_ui_enabled

    def show
      authorize :provisioning, :show?
      @provisioning = default_form_values
    end

    def create
      authorize :provisioning, :create?
      @provisioning = provisioning_params.to_h

      missing = required_keys.select { |key| @provisioning[key].to_s.strip.blank? }
      if missing.any?
        flash.now[:alert] = "Champs requis manquants: #{missing.join(', ')}"
        @generated = nil
        render :show, status: :unprocessable_entity
        return
      end

      @generated = build_generated_payload(@provisioning)
      render :show
    end

    private

    def ensure_provisioning_ui_enabled
      return if ENV["PROVISIONING_UI_ENABLED"].to_s == "true"

      head :not_found
    end

    def provisioning_params
      params
        .require(:provisioning)
        .permit(
          :heroku_app,
          :client_domain,
          :app_protocol,
          :app_base_url,
          :stripe_secret_key,
          :mail_from,
          :stripe_webhook_secret,
          :smtp_address,
          :smtp_port,
          :smtp_username,
          :smtp_password,
          :smtp_domain,
          :smtp_starttls,
          :smtp_ssl,
          :smtp_auth,
          :create_app,
          :add_domain,
          :scale,
          :db_prepare
        )
    end

    def required_keys
      %w[heroku_app client_domain stripe_secret_key mail_from]
    end

    def default_form_values
      {
        "heroku_app" => "",
        "client_domain" => "",
        "app_protocol" => "https",
        "app_base_url" => "",
        "stripe_secret_key" => "",
        "stripe_webhook_secret" => "",
        "mail_from" => "",
        "smtp_address" => "",
        "smtp_port" => "587",
        "smtp_username" => "",
        "smtp_password" => "",
        "smtp_domain" => "",
        "smtp_starttls" => "true",
        "smtp_ssl" => "false",
        "smtp_auth" => "plain",
        "create_app" => "1",
        "add_domain" => "1",
        "scale" => "1",
        "db_prepare" => "1"
      }
    end

    def build_generated_payload(input)
      heroku_app = input.fetch("heroku_app").to_s.strip
      client_domain = input.fetch("client_domain").to_s.strip
      app_protocol = input["app_protocol"].to_s.strip.presence || "https"
      app_base_url = input["app_base_url"].to_s.strip
      app_base_url = "#{app_protocol}://#{client_domain}" if app_base_url.blank?

      env_pairs = {
        "HEROKU_APP" => heroku_app,
        "CLIENT_DOMAIN" => client_domain,
        "STRIPE_SECRET_KEY" => input.fetch("stripe_secret_key").to_s.strip,
        "MAIL_FROM" => input.fetch("mail_from").to_s.strip
      }

      env_pairs["APP_PROTOCOL"] = app_protocol if input["app_protocol"].to_s.strip.present?
      env_pairs["APP_BASE_URL"] = app_base_url if input["app_base_url"].to_s.strip.present?

      if input["smtp_address"].to_s.strip.present?
        env_pairs["SMTP_ADDRESS"] = input["smtp_address"].to_s.strip
        env_pairs["SMTP_PORT"] = input["smtp_port"].to_s.strip.presence || "587"
        env_pairs["SMTP_USERNAME"] = input["smtp_username"].to_s
        env_pairs["SMTP_PASSWORD"] = input["smtp_password"].to_s
        env_pairs["SMTP_DOMAIN"] = input["smtp_domain"].to_s
        env_pairs["SMTP_STARTTLS"] = input["smtp_starttls"].to_s.strip.presence || "true"
        env_pairs["SMTP_SSL"] = input["smtp_ssl"].to_s.strip.presence || "false"
        env_pairs["SMTP_AUTH"] = input["smtp_auth"].to_s.strip.presence || "plain"
      end

      if input["stripe_webhook_secret"].to_s.strip.present?
        env_pairs["STRIPE_WEBHOOK_SECRET"] = input["stripe_webhook_secret"].to_s.strip
      end

      flags = []
      flags << "--create-app" if truthy?(input["create_app"])
      flags << "--add-domain" if truthy?(input["add_domain"])
      flags << "--scale" if truthy?(input["scale"])
      flags << "--db-prepare" if truthy?(input["db_prepare"])

      command_lines = []
      env_pairs.each do |key, value|
        next if value.nil?

        escaped = Shellwords.escape(value.to_s)
        command_lines << "#{key}=#{escaped} \\\n"
      end

      command_lines << "./script/provision_client.sh #{flags.join(' ')}".rstrip

      webhook_url = "#{app_base_url}/stripe/webhook"
      events = [
        "checkout.session.completed",
        "checkout.session.async_payment_failed",
        "checkout.session.expired",
        "refund.updated"
      ]

      {
        command: command_lines.join,
        heroku_app:,
        client_domain:,
        webhook_url:,
        events:
      }
    end

    def truthy?(value)
      value.to_s == "1" || value.to_s.casecmp("true").zero?
    end
  end
end
