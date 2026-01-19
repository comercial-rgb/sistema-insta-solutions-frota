class ContractPolicy < ApplicationPolicy

  def general_can_access?
    !user.nil? && !user.provider?
  end

  def index?
    general_can_access?
  end

  def create?
    user.admin?
  end

  def new?
    create?
  end

  def update?
    user.admin?
  end

  def edit?
    update?
  end

  def destroy?
    required_order_service_statuses = OrderServiceStatus::REQUIRED_ORDER_SERVICE_STATUSES
    required_proposal_statuses = OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES
    general_can_access? && record.order_services.joins(:order_service_proposals)
    .where(order_service_status_id: required_order_service_statuses)
    .where(order_service_proposals: { order_service_proposal_status_id: required_proposal_statuses }).empty?
  end

  def show?
    index?
  end

  def addendum_contracts?
    update?
  end

end
