class AddressPolicy < ApplicationPolicy
  
  def general_can_access?
    user.admin? || user.user?
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
    user.admin? || (user.user? && (record.ownertable_type == "User" && record.ownertable_id == user.id))
  end

  def edit?
    update?
  end

  def destroy?
    user.admin? || (user.user? && (record.ownertable_type == "User" && record.ownertable_id == user.id))
  end

end