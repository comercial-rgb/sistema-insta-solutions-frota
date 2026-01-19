class SiteContactPolicy < ApplicationPolicy

  def index?
    if user.id == User::ADMIN_FIRST_ID
      return true
    else
      return false
    end
  end

  def create?
    !user.nil?
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    if user.id == User::ADMIN_FIRST_ID
      return true
    else
      return false
    end
  end

end
