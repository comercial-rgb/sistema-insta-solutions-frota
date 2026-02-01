class CommitmentPolicy < ApplicationPolicy

  def general_can_access?
    user.admin? || user.client? || user.manager? || user.additional?
  end

  def index?
    general_can_access?
  end

  def show?
    general_can_access?
  end

  def create?
    general_can_access?
  end

  def new?
    create?
  end

  def update?
    record.persisted?
  end

  def edit?
    update?
  end
  
  # Admin pode editar Valor do empenho e N° do empenho mesmo com OS aprovadas
  def can_edit_value_and_number?
    user.admin? && record.persisted?
  end

  def inactivate?
    general_can_access? && record.persisted?
  end

  def destroy?
    required_order_service_statuses = OrderServiceStatus::REQUIRED_ORDER_SERVICE_STATUSES
    required_proposal_statuses = OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES
    (user.admin? || user.client?) && record.order_services.joins(:order_service_proposals)
    .where(order_service_status_id: required_order_service_statuses)
    .where(order_service_proposals: { order_service_proposal_status_id: required_proposal_statuses }).empty?
  end

  def save_cancel_commitment?
    general_can_access? && record.persisted?
  end

  def edit_commitment?
    user.admin? && record.persisted? && !record.valid?
  end

end
