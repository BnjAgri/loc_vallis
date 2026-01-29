class UserPolicy < ApplicationPolicy
  def index?
    user.is_a?(Owner)
  end

  def show?
    user.is_a?(Owner)
  end

  class Scope < Scope
    def resolve
      return scope.none unless user.is_a?(Owner)

      scope.all
    end
  end
end
