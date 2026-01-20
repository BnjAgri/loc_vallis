require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get articles_url(locale: :en)
    assert_response :success
  end

  test "should get show" do
    owner = Owner.create!(
      email: "owner-test@example.com",
      password: "password123",
      guesthouse_name: "Loc Vallis"
    )

    article = Article.create!(
      owner: owner,
      title: "Test article",
      content: "A bit of content",
      image_url: "https://example.com/image.jpg"
    )

    get article_url(article, locale: :en)
    assert_response :success
  end
end
