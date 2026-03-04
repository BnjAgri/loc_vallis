# frozen_string_literal: true

class ProvisioningPolicy
  attr_reader :user

  def initialize(user, _record)
    @user = user
  end

  def show?
    user.is_a?(Owner)
  end

  def create?
    show?
  end
end
