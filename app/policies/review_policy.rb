class ReviewPolicy < ApplicationPolicy
  def create?
    return false unless user.is_a?(User)
    return false if record.booking.nil?

    booking = record.booking

    return false unless booking.user_id == user.id
    return false unless %w[confirmed_paid refunded].include?(booking.status)
    return false unless booking.end_date.present? && Date.current >= booking.end_date
    return false if booking.review&.persisted?

    true
  end
end
