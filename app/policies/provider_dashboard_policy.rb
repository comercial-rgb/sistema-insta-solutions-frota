class ProviderDashboardPolicy < ApplicationPolicy
  def index?
    user.provider?
  end

  def rejections?
    user.provider?
  end

  def bulk_reject?
    user.provider?
  end

  def revert_rejection?
    user.provider?
  end
end
