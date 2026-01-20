require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  test "is valid with an image_url" do
    owner = Owner.create!(email: "owner-article-model-1@example.com", password: "password123")

    article = Article.new(
      owner: owner,
      title: "Title",
      content: "Content",
      image_url: "https://example.com/image.jpg"
    )

    assert article.valid?
  end

  test "is valid with an uploaded image" do
    owner = Owner.create!(email: "owner-article-model-2@example.com", password: "password123")

    article = Article.new(
      owner: owner,
      title: "Title",
      content: "Content",
      image_url: nil
    )

    article.image.attach(
      io: StringIO.new("fake"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )

    assert article.valid?
  end

  test "is invalid without an image_url or uploaded image" do
    owner = Owner.create!(email: "owner-article-model-3@example.com", password: "password123")

    article = Article.new(
      owner: owner,
      title: "Title",
      content: "Content",
      image_url: nil
    )

    assert_not article.valid?
    assert article.errors[:image_url].present?
  end
end
