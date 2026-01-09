class MessagePolicy < ApplicationPolicy
  def create?
    return false unless user.present?

    booking = record.booking
    return false if booking.nil?

    participant?(booking)
  end

  private

  def participant?(booking)
    return true if user.is_a?(Owner) && booking.room&.owner_id == user.id
    return true if user.is_a?(User) && booking.user_id == user.id

    false
  end
end
