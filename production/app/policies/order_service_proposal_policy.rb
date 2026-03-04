class OrderServiceProposalPolicy < ApplicationPolicy

  def general_can_access?
    user.provider?
  end

  def index?
    general_can_access?
  end

  def show_order_service_proposals?
    general_can_access?
  end

  def create?
    user.provider?
  end

  def new?
    create?
  end

  def update?
    (general_can_access? && record.provider_id == user.id && ([OrderServiceStatus::EM_ABERTO_ID, OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID, OrderServiceStatus::EM_REAVALIACAO_ID].include?(record.order_service.order_service_status_id))) || user.admin?
  end

  def edit_proposal_in_reevaluation?
    user.provider? && 
    record.order_service.order_service_status_id == OrderServiceStatus::EM_REAVALIACAO_ID &&
    record.provider_id == user.id &&
    [
      OrderServiceProposalStatus::EM_CADASTRO_ID,
      OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID
    ].include?(record.order_service_proposal_status_id)
  end

  def can_insert_invoices?
    # Permite fornecedor, admin, gestor e adicional inserir/editar notas fiscais
    (general_can_access? && record.provider_id == user.id && ([OrderServiceStatus::APROVADA_ID].include?(record.order_service.order_service_status_id))) || 
    user.admin? || 
    ((user.manager? || user.additional?) && user.client_id == record.order_service.client_id)
  end

  def edit?
    update?
  end

  def destroy?
    # Rails.env.development?
    false
  end

  def can_edit_order_service_proposal?
    user.admin? || ((user.manager? || user.additional?) && (user.client_id == record.order_service.client_id))
  end

  def show_order_service_proposal?
    can_edit_order_service_proposal? || (user.provider? && user.id == record.provider_id)
  end

  def approve_order_service_proposal?
    can_edit_order_service_proposal? && 
    record.order_service_proposal_status_id == OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID && 
    (record.order_service.order_service_status_id == OrderServiceStatus::EM_ABERTO_ID || record.order_service.order_service_status_id == OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID) && 
    (record.order_service.commitment_id.blank? || record.can_manage_by_pendent_value)
  end

  def reprove_order_service_proposal?
    can_edit_order_service_proposal? && 
    record.order_service_proposal_status_id == OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID && 
    (record.order_service.order_service_status_id == OrderServiceStatus::EM_ABERTO_ID || record.order_service.order_service_status_id == OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID) && 
    (record.order_service.commitment_id.blank? || record.can_manage_by_pendent_value)
  end

  def autorize_order_service_proposal?
    can_edit_order_service_proposal? && record.order_service.order_service_status_id == OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID
  end

  def waiting_payment_order_service_proposal?
    can_edit_order_service_proposal? && user.admin? && record.order_service_proposal_status_id == OrderServiceProposalStatus::AUTORIZADA_ID && record.order_service.order_service_status_id == OrderServiceStatus::AUTORIZADA_ID
  end

  def paid_order_service_proposal?
    can_edit_order_service_proposal? && user.admin? && record.order_service_proposal_status_id == OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID && record.order_service.order_service_status_id == OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID
  end

  def reprove_order_service_proposals?
    user.admin? || user.manager? || user.additional?
  end

  def manager_refuse_additional_approval?
    (user.admin? || user.manager?) && record.pending_manager_approval && record.approved_by_additional_id.present?
  end

  def manager_refuse_additional_authorization?
    (user.admin? || user.manager?) && record.pending_manager_authorization && record.authorized_by_additional_id.present?
  end

  def cancel_order_service_proposal?
    user.provider? && record.provider_id == user.id && record.order_service_proposal_status_id == OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID && (record.order_service.order_service_status_id == OrderServiceStatus::EM_ABERTO_ID || record.order_service.order_service_status_id == OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID)
  end

  def get_new_proposals_order_service_proposal?
    (user.admin? || user.manager? || user.additional?) &&
    record.order_service.order_service_type_id == OrderServiceType::DIAGNOSTICO_ID &&
    record.provider_id == record.order_service.provider_id &&
    record.order_service_proposal_status_id == OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID &&
    (record.order_service.order_service_status_id == OrderServiceStatus::EM_ABERTO_ID || record.order_service.order_service_status_id == OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID)
  end

  def can_view_reason_approved?
    user.admin? || user.manager? || user.additional?
  end

end
