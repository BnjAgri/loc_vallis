class Article < ApplicationRecord
  belongs_to :owner

  has_one_attached :image

  validates :title, presence: true
  validates :content, presence: true
  validate :cover_image_present

  private

  def cover_image_present
    return if image.attached? || image_url.present?

    errors.add(:image_url, :blank)
  end
end
