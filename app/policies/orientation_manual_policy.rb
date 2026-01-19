class OrientationManualPolicy < ApplicationPolicy

  def general_can_access?
    !user.nil?
  end

  def index?
    general_can_access?
  end

  def create?
    user.admin?
  end

  def new?
    create?
  end

  def update?
    user.admin?
  end

  def edit?
    update?
  end

  def destroy?
    user.admin?
  end

end
