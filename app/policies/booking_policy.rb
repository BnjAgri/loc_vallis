class BookingPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return false unless user.present?

    owner_for_room? || record.user_id == user.id
  end

  def create?
    user.is_a?(User)
  end

  def pay?
    return false unless user.is_a?(User)

    record.user_id == user.id && record.payment_window_open?
  end

  def cancel?
    return false unless user.present?

    return true if owner_for_room?

    record.user_id == user.id && %w[requested approved_pending_payment confirmed_paid].include?(record.status)
  end

  def approve?
    owner_for_room? && record.status == "requested"
  end

  def decline?
    owner_for_room? && record.status == "requested"
  end

  def refund?
    owner_for_room? && record.status == "confirmed_paid" && record.stripe_refund_id.blank?
  end

  class Scope < Scope
    def resolve
      return scope.none if user.nil?
      return scope.joins(:room).where(rooms: { owner_id: user.id }) if user.is_a?(Owner)

      scope.where(user_id: user.id)
    end
  end

  private

  def owner_for_room?
    user.is_a?(Owner) && record.room&.owner_id == user.id
  end
end
