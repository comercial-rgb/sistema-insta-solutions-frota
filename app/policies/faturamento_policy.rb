class FaturamentoPolicy < ApplicationPolicy
  def index?
    user.admin? || user.manager? || user.additional? || user.provider? || user.client?
  end

  def show?
    index?
  end

  def create?
    user.admin? || user.manager?
  end

  def update?
    user.admin? || user.manager?
  end

  def destroy?
    user.admin?
  end

  def resumo?
    index?
  end

  def faturas?
    index?
  end

  def abertos?
    user.admin? || user.manager?
  end

  def config_impostos?
    user.admin?
  end
end
