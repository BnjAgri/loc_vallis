require "test_helper"

class PagesCgvTest < ActionDispatch::IntegrationTest
  test "renders cgv page" do
    get cgv_path
    assert_response :success
  end

  test "back link uses return_to when provided" do
    return_to = "/fr/rooms/39/bookings/new?start_date=2026-01-30&end_date=2026-01-31"
    get cgv_path(return_to: return_to)

    assert_response :success
    assert_includes response.body, "href=\"#{ERB::Util.html_escape(return_to)}\""
  end
end
