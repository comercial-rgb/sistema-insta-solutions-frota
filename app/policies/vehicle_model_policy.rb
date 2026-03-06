class VehicleModelPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    user.admin?
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
    user.admin?
  end
  
  def update_prices?
    user.admin?
  end
  
  def import?
    user.admin?
  end
  
  def export?
    user.admin?
  end
end
