class RoomPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.is_a?(Owner)
  end

  def update?
    user.is_a?(Owner) && record.owner_id == user.id
  end

  def destroy?
    update?
  end

  class Scope < Scope
    def resolve
      return scope.where(owner_id: user.id) if user.is_a?(Owner)

      scope.all
    end
  end
end
