class FinancialPortalController < ApplicationController
  before_action :verify_access

  PORTAL_URL = 'https://portal.frotainstasolutions.com.br'.freeze

  def index
    authorize :financial_portal, :index?

    @provider = @current_user
    
    # Estatísticas do fornecedor no sistema de frotas (dados de referência)
    if @current_user.provider?
      load_provider_stats
    elsif @current_user.admin? || @current_user.manager? || @current_user.additional?
      load_admin_stats
    end
  end

  private

  def verify_access
    unless @current_user.provider? || @current_user.admin? || @current_user.manager? || @current_user.additional?
      redirect_to root_path, alert: "Acesso negado."
    end
  end

  def load_provider_stats
    proposals = OrderServiceProposal.by_provider_id(@current_user.id)
    
    # Contagens por status
    counts = proposals
      .where(order_service_proposal_status_id: [
        OrderServiceProposalStatus::APROVADA_ID,
        OrderServiceProposalStatus::NOTAS_INSERIDAS_ID,
        OrderServiceProposalStatus::AUTORIZADA_ID,
        OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
        OrderServiceProposalStatus::PAGA_ID
      ])
      .group(:order_service_proposal_status_id)
      .count

    @aprovadas_count = counts[OrderServiceProposalStatus::APROVADA_ID] || 0
    @notas_inseridas_count = counts[OrderServiceProposalStatus::NOTAS_INSERIDAS_ID] || 0
    @autorizadas_count = counts[OrderServiceProposalStatus::AUTORIZADA_ID] || 0
    @ag_pagamento_count = counts[OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID] || 0
    @pagas_count = counts[OrderServiceProposalStatus::PAGA_ID] || 0

    # Valores por status
    values = proposals
      .where(order_service_proposal_status_id: [
        OrderServiceProposalStatus::APROVADA_ID,
        OrderServiceProposalStatus::AUTORIZADA_ID,
        OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
        OrderServiceProposalStatus::PAGA_ID
      ])
      .group(:order_service_proposal_status_id)
      .sum(:total_value)

    @valor_aprovado = values[OrderServiceProposalStatus::APROVADA_ID] || 0
    @valor_autorizado = values[OrderServiceProposalStatus::AUTORIZADA_ID] || 0
    @valor_ag_pagamento = values[OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID] || 0
    @valor_pago = values[OrderServiceProposalStatus::PAGA_ID] || 0

    # OSs recentes do fornecedor (para mostrar resumo)
    @os_recentes = OrderService
      .where(provider_id: @current_user.id)
      .where(order_service_status_id: [
        OrderServiceStatus::APROVADA_ID,
        OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID,
        OrderServiceStatus::AUTORIZADA_ID,
        OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID,
        OrderServiceStatus::PAGA_ID
      ])
      .includes(:client, :vehicle, :order_service_status, :cost_center)
      .order(updated_at: :desc)
      .limit(20)
  end

  def load_admin_stats
    # Para admin, mostrar resumo geral
    base_scope = OrderServiceProposal.all
    
    if @current_user.manager? || @current_user.additional?
      client_id = @current_user.client_id
      cost_center_ids = @current_user.associated_cost_centers.map(&:id)
      os_ids = OrderService.by_client_id(client_id).by_cost_center_ids(cost_center_ids).pluck(:id)
      base_scope = base_scope.where(order_service_id: os_ids)
    end

    counts = base_scope
      .where(order_service_proposal_status_id: [
        OrderServiceProposalStatus::APROVADA_ID,
        OrderServiceProposalStatus::AUTORIZADA_ID,
        OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
        OrderServiceProposalStatus::PAGA_ID
      ])
      .group(:order_service_proposal_status_id)
      .count

    @aprovadas_count = counts[OrderServiceProposalStatus::APROVADA_ID] || 0
    @autorizadas_count = counts[OrderServiceProposalStatus::AUTORIZADA_ID] || 0
    @ag_pagamento_count = counts[OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID] || 0
    @pagas_count = counts[OrderServiceProposalStatus::PAGA_ID] || 0
    @notas_inseridas_count = 0

    values = base_scope
      .where(order_service_proposal_status_id: [
        OrderServiceProposalStatus::APROVADA_ID,
        OrderServiceProposalStatus::AUTORIZADA_ID,
        OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
        OrderServiceProposalStatus::PAGA_ID
      ])
      .group(:order_service_proposal_status_id)
      .sum(:total_value)

    @valor_aprovado = values[OrderServiceProposalStatus::APROVADA_ID] || 0
    @valor_autorizado = values[OrderServiceProposalStatus::AUTORIZADA_ID] || 0
    @valor_ag_pagamento = values[OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID] || 0
    @valor_pago = values[OrderServiceProposalStatus::PAGA_ID] || 0
    
    @os_recentes = OrderService.none
  end
end
