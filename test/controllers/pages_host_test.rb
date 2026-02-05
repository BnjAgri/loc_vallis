require "test_helper"

class PagesHostTest < ActionDispatch::IntegrationTest
  test "renders host page" do
    get host_path
    assert_response :success
  end
end
