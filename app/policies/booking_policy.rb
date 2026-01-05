class BookingPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return false unless user.present?

    owner? || record.user_id == user.id
  end

  def create?
    user.is_a?(User)
  end

  def cancel?
    return false unless user.present?

    return true if owner?

    record.user_id == user.id && %w[requested approved_pending_payment confirmed_paid].include?(record.status)
  end

  def approve?
    owner? && record.status == "requested"
  end

  def decline?
    owner? && record.status == "requested"
  end

  class Scope < Scope
    def resolve
      return scope.none if user.nil?
      return scope.all if user.is_a?(Owner)

      scope.where(user_id: user.id)
    end
  end

  private

  def owner?
    user.is_a?(Owner)
  end
end
