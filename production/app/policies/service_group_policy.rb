class ServiceGroupPolicy < ApplicationPolicy

  def general_can_access?
    user.admin?
  end

  def index?
    general_can_access?
  end

  def create?
    general_can_access?
  end

  def new?
    create?
  end

  def update?
    user.admin? || user.manager?
  end

  def edit?
    update?
  end

  def destroy?
    general_can_access?
  end

  def show?
    # Admin, Manager e Additional podem visualizar grupos para criar OS do tipo Requisição
    user.admin? || user.manager? || user.additional?
  end

end
