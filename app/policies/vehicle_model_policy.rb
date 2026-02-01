class VehicleModelPolicy < ApplicationPolicy
  def index?
    # Fornecedores não têm acesso aos modelos de veículos
    user.present? && !user.provider?
  end

  def show?
    # Fornecedores não têm acesso aos modelos de veículos
    user.present? && !user.provider?
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
  
  def manage_prices?
    user.admin? || user.manager? || user.additional?
  end
  
  def update_prices?
    user.admin?
  end
  
  def import?
    user.admin?
  end
  
  def export?
    user.admin? || user.manager? || user.additional?
  end
end
