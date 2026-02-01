class NotificationPolicy < ApplicationPolicy

  def general_can_access?
    !user.nil?
  end

  def index?
    general_can_access?
  end

  def index_by_menu?
    general_can_access? && user.admin?
  end

  def create?
    user.admin?
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
    user.admin?
  end

  def check_all_read_notifications?
    !user.nil?
  end

end
