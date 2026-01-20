class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_owner_unread_conversations_count, if: :owner_signed_in?
  before_action :set_user_unread_conversations_count, if: :user_signed_in?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # With two Devise scopes (Owner + User), Pundit needs a single actor.
  def pundit_user
    current_owner || current_user
  end

  protected

  def configure_permitted_parameters
    keys = %i[first_name last_name]

    case resource_name
    when :user
      keys += %i[postal_address phone]
    when :owner
      keys += %i[guesthouse_name postal_address phone]
    end

    devise_parameter_sanitizer.permit(:sign_up, keys: keys)
    devise_parameter_sanitizer.permit(:account_update, keys: keys)
  end

  private

  def set_locale
    requested_locale = params[:locale]&.to_sym

    I18n.locale =
      if requested_locale && I18n.available_locales.include?(requested_locale)
        requested_locale
      else
        I18n.default_locale
      end
  end

  def default_url_options
    locale_param = I18n.locale == I18n.default_locale ? nil : I18n.locale
    super.merge(locale: locale_param)
  end

  def set_owner_unread_conversations_count
    bookings_scope = policy_scope(Booking)

    @owner_unread_conversations_count = bookings_scope
      .joins(:messages)
      .where(messages: { sender_type: "User" })
      .where("messages.created_at > COALESCE(bookings.owner_last_read_at, ?)", Time.at(0))
      .distinct
      .count
  end

  def set_user_unread_conversations_count
    bookings_scope = policy_scope(Booking)

    @user_unread_conversations_count = bookings_scope
      .joins(:messages)
      .where(messages: { sender_type: "Owner" })
      .where("messages.created_at > COALESCE(bookings.user_last_read_at, ?)", Time.at(0))
      .distinct
      .count
  end

  def user_not_authorized
    flash[:alert] = t("shared.authorization.not_authorized")
    redirect_back(fallback_location: root_path)
  end
end
