require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get articles_url(locale: :en)
    assert_response :success
  end

  test "unauthenticated should redirect from new" do
    get new_article_url(locale: :en)
    assert_redirected_to login_url(locale: :en)
  end

  test "user should be blocked from new" do
    user = User.create!(
      email: "user-test@example.com",
      password: "password123",
      first_name: "Test",
      last_name: "User"
    )

    sign_in user

    get new_article_url(locale: :en)
    assert_redirected_to root_url(locale: :en)
  end

  test "owner can create an article" do
    owner = Owner.create!(
      email: "owner-create@example.com",
      password: "password123",
      guesthouse_name: "Loc Vallis"
    )

    sign_in owner

    assert_difference("Article.count", 1) do
      post articles_url(locale: :en), params: {
        article: {
          title: "New article",
          content: "Some content",
          image_url: "https://example.com/image.jpg"
        }
      }
    end

    assert_redirected_to article_url(Article.order(:created_at).last, locale: :en)
  end

  test "owner can edit and update own article" do
    owner = Owner.create!(
      email: "owner-edit@example.com",
      password: "password123",
      guesthouse_name: "Loc Vallis"
    )

    article = Article.create!(
      owner: owner,
      title: "Old",
      content: "Old content",
      image_url: "https://example.com/image.jpg"
    )

    sign_in owner

    get edit_article_url(article, locale: :en)
    assert_response :success

    patch article_url(article, locale: :en), params: { article: { title: "New" } }
    assert_redirected_to article_url(article, locale: :en)
    assert_equal "New", article.reload.title
  end

  test "owner cannot edit another owner's article" do
    owner_a = Owner.create!(email: "owner-a@example.com", password: "password123")
    owner_b = Owner.create!(email: "owner-b@example.com", password: "password123")

    article = Article.create!(
      owner: owner_a,
      title: "A",
      content: "Content",
      image_url: "https://example.com/image.jpg"
    )

    sign_in owner_b

    get edit_article_url(article, locale: :en)
    assert_redirected_to articles_url(locale: :en)
  end

  test "owner can destroy own article" do
    owner = Owner.create!(email: "owner-destroy@example.com", password: "password123")

    article = Article.create!(
      owner: owner,
      title: "To delete",
      content: "Content",
      image_url: "https://example.com/image.jpg"
    )

    sign_in owner

    assert_difference("Article.count", -1) do
      delete article_url(article, locale: :en)
    end

    assert_redirected_to articles_url(locale: :en)
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
