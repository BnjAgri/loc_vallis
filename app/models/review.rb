class Review < ApplicationRecord
  belongs_to :booking
  belongs_to :user

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :comment, presence: true
  validates :booking_id, uniqueness: true

  validate :user_matches_booking

  delegate :room, to: :booking

  private

  def user_matches_booking
    return if booking.nil? || user.nil?

    return if booking.user_id == user.id

    errors.add(:user, "must match booking user")
  end
end
