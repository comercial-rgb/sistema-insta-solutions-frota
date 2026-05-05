class MaintenancePlanPolicy < ApplicationPolicy

  def index?
    user.admin? || user.client? || user.manager? || user.additional?
  end

  def show?
    index?
  end

  def create?
    user.admin? || user.client?
  end

  def new?
    create?
  end

  def update?
    user.admin? || user.client?
  end

  def edit?
    update?
  end

  def destroy?
    user.admin?
  end

end
