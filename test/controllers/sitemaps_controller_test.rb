require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test "sitemap.xml returns xml" do
    get "/sitemap.xml"
    assert_response :success
    assert_includes response.media_type, "xml"
    assert_includes response.body, "<urlset"
    assert_includes response.body, "<loc>"
  end
end
