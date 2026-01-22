class ServicesImportPolicy < ApplicationPolicy
  def new?
    user.admin?
  end
  
  def create?
    user.admin?
  end
  
  def template?
    user.admin?
  end
end
