require "test_helper"

class HostPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get host_url(locale: :en)
    assert_response :success
  end

  test "unauthenticated should redirect from edit" do
    get edit_host_url(locale: :en)
    assert_redirected_to login_url(locale: :en)
  end

  test "user should be blocked from edit" do
    user = User.create!(
      email: "user-host@test.local",
      password: "password123",
      first_name: "Test",
      last_name: "User"
    )

    sign_in user

    get edit_host_url(locale: :en)
    assert_redirected_to root_url(locale: :en)
  end

  test "owner can edit and update host page" do
    owner = Owner.create!(email: "owner-host@test.local", password: "password123")
    sign_in owner

    get edit_host_url(locale: :en)
    assert_response :success

    assert_difference("HostPage.count", 1) do
      patch host_url(locale: :en), params: {
        host_page: {
          title: "My host page",
          content: "Hello world",
          image_url: "https://example.com/image.jpg"
        }
      }
    end

    assert_redirected_to host_url(locale: :en)
    assert_equal "My host page", HostPage.first.title
  end
end
