class PagesController < ApplicationController
  def legal
    load_publisher_info
  end

  def cgv
    load_publisher_info

    @back_url = safe_return_to(params[:return_to]) || root_path
  end

  private

  def load_publisher_info
    @owner = Owner.order(:created_at).first

    @publisher_name = ENV["LEGAL_PUBLISHER_NAME"].presence || @owner&.guesthouse_name.presence || @owner&.display_name.presence
    @publisher_email = ENV["LEGAL_PUBLISHER_EMAIL"].presence || @owner&.email.presence
    @publisher_phone = ENV["LEGAL_PUBLISHER_PHONE"].presence || @owner&.phone.presence
    @publisher_address = ENV["LEGAL_PUBLISHER_ADDRESS"].presence || @owner&.postal_address.presence
    @publisher_siret = ENV["LEGAL_PUBLISHER_SIRET"].presence

    @host_name = ENV["LEGAL_HOST_NAME"].presence
    @host_address = ENV["LEGAL_HOST_ADDRESS"].presence
    @host_phone = ENV["LEGAL_HOST_PHONE"].presence
  end

  def safe_return_to(value)
    path = value.to_s
    return nil if path.blank?
    return nil unless path.start_with?("/")
    return nil if path.start_with?("//")
    return nil if path.include?("\n") || path.include?("\r")
    return nil if path.start_with?("/stripe/webhook")

    path
  end
end
