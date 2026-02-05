## BookingPolicy
# Autorisations Pundit pour les actions sur les bookings.
#
# Modèle d'acteurs :
# - `User` : accès à ses propres bookings.
# - `Owner` : accès aux bookings des rooms qu'il possède.
#
# NB : `Scope#resolve` reflète strictement cette séparation.
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

    # A paid booking must be refunded (full or partial) rather than canceled.
    return owner_for_room? && %w[requested approved_pending_payment].include?(record.status) if owner_for_room?

    record.user_id == user.id && %w[requested approved_pending_payment].include?(record.status)
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
