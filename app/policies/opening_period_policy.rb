class OpeningPeriodPolicy < ApplicationPolicy
  def create?
    owner_for_room?
  end

  def edit?
    owner_for_room?
  end

  def update?
    owner_for_room?
  end

  def destroy?
    owner_for_room?
  end

  class Scope < Scope
    def resolve
      return scope.none if user.nil?
      return scope.joins(:room).where(rooms: { owner_id: user.id }) if user.is_a?(Owner)

      scope.none
    end
  end

  private

  def owner_for_room?
    user.is_a?(Owner) && record.room&.owner_id == user.id
  end
end
