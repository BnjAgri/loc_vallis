class UnifiedSessionsController < ApplicationController
  def new
    session[:return_to] = safe_return_to(params[:return_to]) || safe_return_to_from_referer || session[:return_to]
  end

  def email_exists
    email = params[:email].to_s.strip

    exists = false
    if email.present?
      exists = Owner.find_for_database_authentication(email: email).present? ||
        User.find_for_database_authentication(email: email).present?
    end

    render json: { exists: exists }
  end

  def create
    email = params.dig(:session, :email).to_s.strip
    password = params.dig(:session, :password).to_s

    return_to = safe_return_to(params[:return_to]) || session[:return_to]

    if email.blank? || password.blank?
      flash.now[:alert] = t("sessions.flash.missing_credentials")
      render :new, status: :unprocessable_content
      return
    end

    owner = Owner.find_for_database_authentication(email: email)
    if owner.present?
      if owner.valid_password?(password)
        sign_out(:user) if user_signed_in?
        sign_in(:owner, owner)
        session.delete(:return_to)
        set_login_notifications_flash(owner)
        redirect_to(return_to || after_sign_in_path_for(owner))
      else
        flash.now[:alert] = t("sessions.flash.invalid_credentials")
        render :new, status: :unprocessable_content
      end
      return
    end

    user = User.find_for_database_authentication(email: email)
    if user&.valid_password?(password)
      sign_out(:owner) if owner_signed_in?
      sign_in(:user, user)
      session.delete(:return_to)
      set_login_notifications_flash(user)
      redirect_to(return_to || after_sign_in_path_for(user))
    else
      flash.now[:alert] = t("sessions.flash.invalid_credentials")
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    sign_out(:owner) if owner_signed_in?
    sign_out(:user) if user_signed_in?
    redirect_to root_path, notice: t("sessions.flash.logged_out")
  end

  private

  # Prevent open redirects: allow only relative paths.
  def safe_return_to(value)
    path = value.to_s
    return nil if path.blank?
    return nil unless path.start_with?("/")
    return nil if path.start_with?("//")

    path
  end

  def safe_return_to_from_referer
    referer = request.referer.to_s
    return nil if referer.blank?

    uri = URI.parse(referer)
    return nil if uri.host.present? && uri.host != request.host

    path = uri.path.to_s
    return nil if path.blank?
    return nil if path == login_path

    full_path = path
    full_path += "?#{uri.query}" if uri.query.present?

    safe_return_to(full_path)
  rescue URI::InvalidURIError
    nil
  end
end
