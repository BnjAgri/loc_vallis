class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # With two Devise scopes (Owner + User), Pundit needs a single actor.
  def pundit_user
    current_owner || current_user
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[postal_address phone])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[postal_address phone])
  end

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end
end
