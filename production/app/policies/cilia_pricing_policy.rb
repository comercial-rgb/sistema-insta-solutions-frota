class CiliaPricingPolicy < Struct.new(:user, :cilia_pricing)
  def index?
    user.admin?
  end

  def show?
    user.admin?
  end

  def update_prices?
    user.admin?
  end

  def mark_complete?
    user.admin?
  end
end
