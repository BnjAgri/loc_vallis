class Room < ApplicationRecord
  belongs_to :owner

  has_many :opening_periods, dependent: :destroy
  has_many :bookings, dependent: :destroy

  validates :name, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :mvp_room_limit, on: :create

  private

  def mvp_room_limit
    return unless Room.count >= 2

    errors.add(:base, "MVP limit reached: maximum 2 rooms")
  end
end
