require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "edit redirects to login when signed out" do
    get edit_profile_path
    assert_redirected_to login_path(return_to: edit_profile_path)
  end

  test "user can view and update profile" do
    user = User.create!(email: "profile_user@test.local", password: "password")
    sign_in user

    get edit_profile_path
    assert_response :success

    patch profile_path, params: { user: { first_name: "Jean", last_name: "Dupont", phone: "0600000000" } }
    assert_redirected_to edit_profile_path

    user.reload
    assert_equal "Jean", user.first_name
    assert_equal "Dupont", user.last_name
    assert_equal "0600000000", user.phone
  end

  test "user cannot change email without current password" do
    user = User.create!(email: "profile_email_user@test.local", password: "password")
    sign_in user

    patch profile_path, params: { user: { email: "new_email@test.local", current_password: "" } }
    assert_response :unprocessable_entity

    user.reload
    assert_equal "profile_email_user@test.local", user.email
  end

  test "user can change email with current password" do
    user = User.create!(email: "profile_email_ok_user@test.local", password: "password")
    sign_in user

    patch profile_path, params: { user: { email: "new_email_ok@test.local", current_password: "password" } }
    assert_redirected_to edit_profile_path

    user.reload
    assert_equal "new_email_ok@test.local", user.email
  end

  test "user can change password with current password" do
    user = User.create!(email: "profile_password_user@test.local", password: "password")
    sign_in user

    patch profile_path, params: {
      user: {
        password: "newpassword",
        password_confirmation: "newpassword",
        current_password: "password"
      }
    }
    assert_redirected_to edit_profile_path

    user.reload
    assert user.valid_password?("newpassword")
  end

  test "user can delete account" do
    user = User.create!(email: "profile_delete_user@test.local", password: "password")
    sign_in user

    assert_difference "User.count", -1 do
      delete profile_path
    end

    assert_redirected_to root_path
  end

  test "owner can view and update profile" do
    owner = Owner.create!(email: "profile_owner@test.local", password: "password")
    sign_in owner

    get edit_profile_path
    assert_response :success

    patch profile_path, params: { owner: { first_name: "Claude", guesthouse_name: "Chez Claude" } }
    assert_redirected_to edit_profile_path

    owner.reload
    assert_equal "Claude", owner.first_name
    assert_equal "Chez Claude", owner.guesthouse_name
  end

  test "owner can change email with current password" do
    owner = Owner.create!(email: "profile_owner_email@test.local", password: "password")
    sign_in owner

    patch profile_path, params: { owner: { email: "new_owner_email@test.local", current_password: "password" } }
    assert_redirected_to edit_profile_path

    owner.reload
    assert_equal "new_owner_email@test.local", owner.email
  end

  test "owner cannot delete account" do
    owner = Owner.create!(email: "profile_owner_no_delete@test.local", password: "password")
    sign_in owner

    assert_no_difference "Owner.count" do
      delete profile_path
    end

    assert_response :not_found
  end
end
