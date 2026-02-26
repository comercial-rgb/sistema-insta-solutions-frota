class OrderServicePolicy < ApplicationPolicy

  def general_can_access?
    user.admin? || user.manager? || user.additional?
  end

  def index?
    user.admin? || user.manager? || user.additional? || user.provider?
  end

  def show?
    Rails.logger.debug "=== OrderServicePolicy#show? ==="
    Rails.logger.debug "User: #{user.id} - #{user.email}"
    Rails.logger.debug "User Type: Admin=#{user.admin?} Manager=#{user.manager?} Additional=#{user.additional?} Provider=#{user.provider?}"
    Rails.logger.debug "OS: #{record.id} - Code: #{record.code} - Client: #{record.client_id}"
    Rails.logger.debug "OS Status: #{record.order_service_status_id}"
    Rails.logger.debug "Admin? #{user.admin?}"
    Rails.logger.debug "Manager/Additional + ClientMatch? #{(user.manager? || user.additional?) && record.client_id == user.client_id}"
    
    return true if user.admin?
    return true if (user.manager? || user.additional?) && record.client_id == user.client_id
    return true if user.provider? && (record.provider_id == user.id || record.order_service_proposals.exists?(provider_id: user.id))
    
    Rails.logger.debug "Access DENIED!"
    false
  end

  def show_invoices?
    general_can_access?
  end

  def order_service_proposals?
    !user.nil?
  end

  def show_order_services?
    user.admin? || user.manager? || user.additional? || user.provider?
  end

  def create?
    general_can_access?
  end

  def new?
    create?
  end

  # Admin/Gestor/Adicional podem editar o cabeçalho da OS em qualquer status não-terminal
  def can_edit_header?
    return true unless record.persisted?
    
    terminal_statuses = [OrderServiceStatus::CANCELADA_ID, OrderServiceStatus::PAGA_ID]
    
    if user.admin? || (user.manager? && record.client_id == user.client_id) || (user.additional? && record.client_id == user.client_id)
      return !terminal_statuses.include?(record.order_service_status_id)
    end
    
    false
  end

  def can_edit?
    # Se a OS não foi persistida ainda (nova), permite edição
    return true unless record.persisted?
    
    # Fornecedor: pode editar Diagnóstico em aberto ou em reavaliação quando atribuído a ele
    return true if user.provider? && record.order_service_type_id == OrderServiceType::DIAGNOSTICO_ID && [OrderServiceStatus::EM_ABERTO_ID, OrderServiceStatus::EM_REAVALIACAO_ID].include?(record.order_service_status_id) && record.provider_id == user.id
    
    # Admin/Gestor/Adicional: podem editar OS quando:
    # 1. OS está em status editável (Em Aberto ou Aguardando Avaliação)
    # 2. Não existem propostas ativas (não canceladas/reprovadas)
    if user.admin? || (user.manager? && record.client_id == user.client_id) || (user.additional? && record.client_id == user.client_id)
      is_editable_status = [OrderServiceStatus::EM_ABERTO_ID, OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID].include?(record.order_service_status_id)
      has_no_active_proposals = !record.has_active_proposals?
      return is_editable_status && has_no_active_proposals
    end
    
    false
  end

  def update?
    can_edit_header? || can_edit?
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def cancel_order_service?
    (![OrderServiceStatus::CANCELADA_ID].include?(record.order_service_status_id)) && (user.admin? || ((user.manager? || user.additional?) && record.client_id == user.client_id && record.order_service_status_id < OrderServiceStatus::AUTORIZADA_ID))
  end

  def can_generate_proposal?
    (
      user.provider? &&
      !user.rejected_order_services.exists?(id: record.id) &&
      (record.order_service_status_id == OrderServiceStatus::EM_ABERTO_ID || record.order_service_status_id == OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID) &&
      !record.order_service_proposals.where(provider_id: user.id, order_service_proposal_status_id: [
        OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID,
        OrderServiceProposalStatus::APROVADA_ID,
        OrderServiceProposalStatus::NOTAS_INSERIDAS_ID,
        OrderServiceProposalStatus::AUTORIZADA_ID,
        OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
        OrderServiceProposalStatus::PAGA_ID,
      ]).exists? &&
      record.provider_id != user.id &&
      (!record.directed_to_specific_providers? || record.directed_providers.exists?(id: user.id))
    )
  end

  def show_order_service_proposals_by_order_service?
    record.order_service_status_id != OrderServiceStatus::EM_CADASTRO_ID && (user.admin? || ((user.manager? || user.additional?) && record.client_id == user.client_id))
  end

  def show_order_service_proposals_by_order_service_historic?
    (user.admin? || ((user.manager? || user.additional?) && record.client_id == user.client_id))
  end

  def print_order_service_proposals_by_order_service?
    show_order_service_proposals_by_order_service?
  end

  def can_update_status?
    user.admin? || user.manager? || user.additional?
  end

  def authorize_order_services?
    can_update_status?
  end

  def waiting_payment_order_services?
    can_update_status?
  end

  def make_payment_order_services?
    can_update_status?
  end

  def show_historic?
    show_order_service_proposals_by_order_service_historic?
  end

  def can_manage?
    user.admin? || ((user.manager? || user.additional?) && user.client_id == record.client_id)
  end

  def reject_order_service?
    (user.provider? && !user.rejected_order_services.exists?(id: record.id)) && (record.order_service_status_id == OrderServiceStatus::EM_ABERTO_ID || record.order_service_status_id == OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID) && record.provider_id != user.id
  end

  def unreject_order_service?
    (user.provider? && user.rejected_order_services.exists?(id: record.id)) && ([OrderServiceStatus::EM_ABERTO_ID, OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID].include?(record.order_service_status_id))
  end

  def dashboard?
    user.admin? || ((user.manager? || user.additional?))
  end

  def rejected_history?
    user.admin? || user.manager? || user.additional?
  end

  def back_to_edit_order_service?
    false
    # record.order_service_status_id <= OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID && (![OrderServiceStatus::CANCELADA_ID].include?(record.order_service_status_id)) && (user.admin? || ((user.manager? || user.additional?) && record.client_id == user.client_id))
  end

  def print_no_values?
    user.admin? || user.manager? || user.additional? || user.provider?
  end

  def print_os?
    user.admin? || user.manager? || user.additional?
  end
  
  # Permissão para solicitar reavaliação (apenas Diagnóstico em Aguardando avaliação)
  def request_reevaluation?
    record.can_request_reevaluation? && 
    (user.admin? || user.manager? || (user.additional? && record.client_id == user.client_id))
  end
  
  # Permissão para editar proposta durante reavaliação (apenas fornecedor da proposta)
  def edit_reevaluation?
    record.in_reevaluation? && 
    user.provider? && 
    record.provider_id == user.id
  end
  
  # Permissão para realizar complemento (OS aprovada)
  def add_complement?
    record.can_add_complement? &&
    user.provider? &&
    record.approved_proposal&.provider_id == user.id
  end
  
  # Permissão para aprovar complemento
  def approve_complement?
    user.admin? || user.manager? || (user.additional? && record.client_id == user.client_id)
  end
  
  # Permissão para editar peças/serviços em Cotações/Requisições (pode cancelar propostas)
  def manage_parts_services?
    terminal_statuses = [OrderServiceStatus::CANCELADA_ID, OrderServiceStatus::PAGA_ID]
    
    !terminal_statuses.include?(record.order_service_status_id) &&
    [OrderServiceType::COTACOES_ID, OrderServiceType::REQUISICAO_ID].include?(record.order_service_type_id) &&
    (user.admin? || user.manager? || (user.additional? && record.client_id == user.client_id))
  end
  
  # Permissão especial para ADMIN/GESTOR/ADICIONAL editar campos de empenho, contrato e centro de custo
  # mesmo quando já existem propostas, em qualquer status não-terminal
  def can_edit_commitment_fields?
    # Se não foi persistida, permite edição
    return true unless record.persisted?
    
    # Admin, Gestor ou Adicional (do mesmo cliente) podem editar empenho em qualquer status não-terminal
    terminal_statuses = [OrderServiceStatus::CANCELADA_ID, OrderServiceStatus::PAGA_ID]
    
    (user.admin? || 
     (user.manager? && record.client_id == user.client_id) || 
     (user.additional? && record.client_id == user.client_id)) &&
    !terminal_statuses.include?(record.order_service_status_id)
  end
  
  # Verifica se pode editar campos básicos (fornecedor, placa, km, etc)
  def can_edit_basic_fields?
    # Se não foi persistida, permite edição
    return true unless record.persisted?
    
    # Admin/Gestor/Adicional: podem editar campos básicos se podem editar cabeçalho
    if user.admin? || (user.manager? && record.client_id == user.client_id) || (user.additional? && record.client_id == user.client_id)
      return can_edit_header?
    end
    
    # Fornecedor: usa lógica original (can_edit?)
    return false unless can_edit?
    
    # Para Diagnóstico: permite editar fornecedor, placa e empenho
    if record.order_service_type_id == OrderServiceType::DIAGNOSTICO_ID
      return true
    end
    
    # Para Cotações/Requisições: permite editar todos os campos básicos
    if [OrderServiceType::COTACOES_ID, OrderServiceType::REQUISICAO_ID].include?(record.order_service_type_id)
      return true
    end
    
    false
  end

end
