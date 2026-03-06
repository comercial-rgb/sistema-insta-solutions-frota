class CiliaPricingPolicy < Struct.new(:user, :cilia_pricing)
  def index?
    user.admin? || user.manager? || user.additional?
  end

  def show?
    user.admin? || user.manager? || user.additional?
  end

  def update_prices?
    user.admin?
  end

  def mark_complete?
    user.admin? || user.manager?
  end
end
