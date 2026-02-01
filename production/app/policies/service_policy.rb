class ServicePolicy < ApplicationPolicy

  def general_can_access?
    user.admin?
  end

  def index?
    general_can_access?
  end

  def create?
    !user.nil?
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
    general_can_access?
  end

  def by_category?
    true # Permitir acesso a todos (fornecedores precisam buscar serviços)
  end

end
