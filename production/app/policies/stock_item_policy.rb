class StockItemPolicy < ApplicationPolicy

  def index?
    user.admin? || user.manager? || user.additional?
  end

  def dashboard?
    index?
  end

  def show?
    return true if user.admin?
    return true if (user.manager? || user.additional?) && record_belongs_to_user_client?
    false
  end

  def new?
    create?
  end

  def create?
    user.admin? || user.manager? || user.additional?
  end

  def edit?
    update?
  end

  def update?
    return true if user.admin?
    return true if (user.manager? || user.additional?) && record_belongs_to_user_client?
    false
  end

  def destroy?
    return true if user.admin?
    return true if (user.manager? || user.additional?) && record_belongs_to_user_client?
    false
  end

  def import_xml?
    create?
  end

  private

  def record_belongs_to_user_client?
    return false unless record.respond_to?(:client_id)
    client_id = user.client_id || user.id
    record.client_id == client_id
  end
end
