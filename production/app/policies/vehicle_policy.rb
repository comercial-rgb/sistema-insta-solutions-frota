class VehiclePolicy < ApplicationPolicy

  def general_can_access?
    user.admin? || user.client?
  end

  def index?
    user.admin? || user.client? || user.manager? || user.additional?
  end

  def show?
    user.admin? || user.client? || user.manager? || user.additional?
  end

  def create?
    general_can_access?
  end

  def new?
    create?
  end

  def update?
    general_can_access?
  end

  def edit?
    update?
  end

  def destroy?
    required_order_service_statuses = OrderServiceStatus::REQUIRED_ORDER_SERVICE_STATUSES
    required_proposal_statuses = OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES
    user.admin? && record.order_services.joins(:order_service_proposals)
    .where(order_service_status_id: required_order_service_statuses)
    .where(order_service_proposals: { order_service_proposal_status_id: required_proposal_statuses }).empty?
  end

  def order_services?
    index?
  end

  def getting_vehicle_by_plate_integration?
    !user.nil?
  end

end
