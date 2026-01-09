## Room
# Représente un logement publié par un `Owner`.
#
# Points d'attention :
# - Les photos utilisent Active Storage (`has_many_attached :photos`).
# - Les disponibilités et le pricing sont portés par `OpeningPeriod`.
# - Règle MVP : limitation volontaire à 2 rooms max (validation on create).
class Room < ApplicationRecord
  belongs_to :owner

  has_many_attached :photos

  has_many :opening_periods, dependent: :destroy
  has_many :bookings, dependent: :destroy

  validates :name, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :mvp_room_limit, on: :create

  def image_urls
    return [] if room_url.blank?

    room_url
      .to_s
      .split(/\r?\n|,/)
      .map(&:strip)
      .reject(&:blank?)
  end

  private

  def mvp_room_limit
    return unless Room.count >= 2

    errors.add(:base, "MVP limit reached: maximum 2 rooms")
  end
end
