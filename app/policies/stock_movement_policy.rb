class StockMovementPolicy < ApplicationPolicy

  def index?
    user.admin? || user.manager? || user.additional?
  end

  def show?
    return true if user.admin?
    if (user.manager? || user.additional?) && record.respond_to?(:stock_item)
      client_id = user.client_id || user.id
      return record.stock_item&.client_id == client_id
    end
    false
  end
end
