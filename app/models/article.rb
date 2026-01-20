class Article < ApplicationRecord
  belongs_to :owner

  validates :title, presence: true
  validates :content, presence: true
  validates :image_url, presence: true
end
