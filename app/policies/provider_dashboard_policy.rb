class ProviderDashboardPolicy < ApplicationPolicy
  def index?
    user.provider?
  end
end
