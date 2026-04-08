class SupportTicketPolicy < ApplicationPolicy

  def general_can_access?
    user.admin? || user.manager? || user.additional? || user.client?
  end

  def index?
    general_can_access?
  end

  def show?
    general_can_access?
  end

  def create?
    general_can_access?
  end

  def new?
    create?
  end

  def add_message?
    general_can_access? && record.open?
  end

  def update_status?
    user.admin?
  end

  def resolve?
    user.admin? && record.open?
  end

  def reopen?
    user.admin? && record.resolved?
  end

  def destroy?
    user.admin?
  end

end
