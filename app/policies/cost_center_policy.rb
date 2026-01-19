class CostCenterPolicy < ApplicationPolicy

  def general_can_access?
    user.admin? || user.client? || user.manager? || user.additional?
  end

  def index?
    general_can_access?
  end

  def show?
    general_can_access?
  end

  def create?
    general_can_access?
  end

  def new?
    create?
  end

  def update?
    general_can_access?
  end

  def edit?
    update?
  end

  def destroy?
    user.admin? || user.client?
  end

end
