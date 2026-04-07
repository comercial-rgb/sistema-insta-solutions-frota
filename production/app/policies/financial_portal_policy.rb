class FinancialPortalPolicy < ApplicationPolicy
  def index?
    user.admin? || user.manager? || user.additional? || user.provider? || user.client?
  end
end
