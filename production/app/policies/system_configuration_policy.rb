class SystemConfigurationPolicy < ApplicationPolicy
  
  def update?
    user.admin?
  end

  def edit?
    update?
  end

  def delete_gerencia_net_certificate?
    update?
  end

end
