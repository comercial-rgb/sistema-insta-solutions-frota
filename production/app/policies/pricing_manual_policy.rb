class PricingManualPolicy < Struct.new(:user, :pricing_manual)
  def index?
    user.admin? || user.provider? || user.client? || user.manager? || user.additional?
  end
end
