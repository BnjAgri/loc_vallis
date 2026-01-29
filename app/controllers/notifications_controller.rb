class NotificationsController < ApplicationController
  before_action :authenticate_actor!

  def mark_read
    session.delete(:login_notifications)
    redirect_to safe_return_to(params[:redirect_to]) || root_path
  end

  private

  def authenticate_actor!
    return if owner_signed_in? || user_signed_in?

    redirect_to login_path(return_to: request.fullpath), alert: t("sessions.flash.invalid_credentials", default: "Veuillez vous connecter.")
  end

  # Prevent open redirects: allow only relative paths.
  def safe_return_to(value)
    path = value.to_s
    return nil if path.blank?
    return nil unless path.start_with?("/")
    return nil if path.start_with?("//")

    path
  end
end