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

  def os_abertos_json?
    abertos?
  end

  def sub_units_json?
    abertos?
  end

  def marcar_pago?
    user.admin?
  end

  def gerar_docx?
    user.admin? || user.manager?
  end

  def config_impostos?
    user.admin?
  end
end
