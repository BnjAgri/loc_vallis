class HostPage < ApplicationRecord
  has_one_attached :image

  validates :title, presence: true
  validates :content, presence: true
  validate :cover_image_present
  validate :validate_image_url
  before_validation :normalize_text_fields

  def safe_image_url
    image_url_valid? ? image_url : nil
  end

  private

  def cover_image_present
    return if image.attached? || image_url.present?

    errors.add(:image_url, :blank)
  end

  def validate_image_url
    return if image_url.blank?

    errors.add(:image_url, :invalid_image_url) unless image_url_valid?
  end

  def image_url_valid?
    uri = URI.parse(image_url.to_s)
    return false unless uri.is_a?(URI::HTTP)

    ext = File.extname(uri.path.to_s).downcase
    return false if ext.blank?

    %w[.jpg .jpeg .png .gif].include?(ext)
  rescue URI::InvalidURIError
    false
  end

  def normalize_text_fields
    sanitizer = ActionView::Base.full_sanitizer

    self.title = sanitizer.sanitize(title.to_s)
    self.content = sanitizer.sanitize(content.to_s)
  end
end
