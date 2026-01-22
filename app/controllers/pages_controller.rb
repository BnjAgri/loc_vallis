class PagesController < ApplicationController
  def legal
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
end
