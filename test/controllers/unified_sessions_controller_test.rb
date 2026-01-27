require "test_helper"

class UnifiedSessionsControllerTest < ActionDispatch::IntegrationTest
  test "login stores referer as return_to when missing" do
    user = User.create!(email: "sessions_referer@test.local", password: "password")

    get login_path, headers: { "HTTP_REFERER" => rooms_path }
    assert_response :success

    post login_path, params: { session: { email: user.email, password: "password" } }
    assert_redirected_to rooms_path
  end

  test "login keeps return_to after invalid password" do
    user = User.create!(email: "sessions_return_to@test.local", password: "password")

    get login_path(return_to: inbox_path)
    assert_response :success

    post login_path, params: { session: { email: user.email, password: "wrong" } }
    assert_response :unprocessable_content

    post login_path, params: { session: { email: user.email, password: "password" } }
    assert_redirected_to inbox_path
  end

  test "email_exists returns whether email is in database" do
    User.create!(email: "existing@test.local", password: "password")

    get login_email_exists_path, params: { email: "existing@test.local" }
    assert_response :success
    assert_equal true, JSON.parse(response.body).fetch("exists")

    get login_email_exists_path, params: { email: "missing@test.local" }
    assert_response :success
    assert_equal false, JSON.parse(response.body).fetch("exists")
  end
end
