class UnifiedSessionsController < ApplicationController
  def new
    session[:return_to] = safe_return_to(params[:return_to])
  end

  def create
    email = params.dig(:session, :email).to_s.strip
    password = params.dig(:session, :password).to_s

    return_to = safe_return_to(params[:return_to]) || session.delete(:return_to)

    if email.blank? || password.blank?
      flash.now[:alert] = "Email et mot de passe requis"
      render :new, status: :unprocessable_entity
      return
    end

    owner = Owner.find_for_database_authentication(email: email)
    if owner.present?
      if owner.valid_password?(password)
        sign_out(:user) if user_signed_in?
        sign_in(:owner, owner)
        redirect_to(return_to || after_sign_in_path_for(owner))
      else
        flash.now[:alert] = "Email ou mot de passe invalide"
        render :new, status: :unprocessable_entity
      end
      return
    end

    user = User.find_for_database_authentication(email: email)
    if user&.valid_password?(password)
      sign_out(:owner) if owner_signed_in?
      sign_in(:user, user)
      redirect_to(return_to || after_sign_in_path_for(user))
    else
      flash.now[:alert] = "Email ou mot de passe invalide"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out(:owner) if owner_signed_in?
    sign_out(:user) if user_signed_in?
    redirect_to root_path, notice: "Déconnecté"
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
end
