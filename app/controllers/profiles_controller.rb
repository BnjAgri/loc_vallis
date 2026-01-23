class ProfilesController < ApplicationController
  before_action :authenticate_actor!

  def edit
    @profile = current_profile
  end

  def update
    @profile = current_profile

    permitted = profile_params

    if sensitive_update?(permitted)
      if @profile.update_with_password(permitted)
        bypass_sign_in(@profile)
        redirect_to edit_profile_path, notice: t("profiles.flash.updated")
      else
        render :edit, status: :unprocessable_content
      end
    else
      safe_attributes = permitted.except(:current_password, :password, :password_confirmation, :email)

      if @profile.update(safe_attributes)
        redirect_to edit_profile_path, notice: t("profiles.flash.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end
  end

  def destroy
    return head :not_found unless user_signed_in?

    user = current_user
    sign_out(:user)
    user.destroy!

    redirect_to root_path, notice: t("profiles.flash.deleted")
  end

  private

  def authenticate_actor!
    return if user_signed_in? || owner_signed_in?

    flash[:alert] = t("shared.authorization.unauthenticated")
    redirect_to login_path(return_to: request.fullpath), status: :see_other
  end

  def current_profile
    current_owner || current_user
  end

  def profile_params
    if owner_signed_in?
      params.require(:owner).permit(
        :first_name,
        :last_name,
        :guesthouse_name,
        :postal_address,
        :phone,
        :email,
        :password,
        :password_confirmation,
        :current_password
      )
    else
      params.require(:user).permit(
        :first_name,
        :last_name,
        :postal_address,
        :phone,
        :email,
        :password,
        :password_confirmation,
        :current_password
      )
    end
  end

  def sensitive_update?(permitted)
    password_present = permitted[:password].present? || permitted[:password_confirmation].present?
    email_changed = permitted[:email].present? && permitted[:email].to_s != current_profile.email.to_s

    password_present || email_changed
  end
end
