class FinancialPortalController < ApplicationController
  before_action :verify_access

  PORTAL_URL = 'https://portal.frotainstasolutions.com.br'.freeze
  SSO_SECRET = '30bfff7ce392036b19d87dd6336c6e326d5312b943e01e3e8926c7aa22136b14'.freeze

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

  def sso_redirect
    authorize :financial_portal, :index?

    # Mapear role do Frota para role do Portal
    portal_role = if @current_user.provider?
                    'fornecedor'
                  elsif @current_user.client?
                    'cliente'
                  elsif @current_user.admin?
                    'admin'
                  else
                    'gerente'
                  end

    # Montar payload com expiração de 120 segundos
    payload = {
      email: @current_user.email,
      nome: @current_user.name,
      role: portal_role,
      frota_user_id: @current_user.id,
      exp: Time.now.to_i + 120,
      nonce: SecureRandom.hex(16)
    }

    # Codificar payload em Base64URL
    payload_b64 = Base64.urlsafe_encode64(payload.to_json, padding: false)

    # Assinar com HMAC-SHA256
    signature = OpenSSL::HMAC.digest('SHA256', SSO_SECRET, payload_b64)
    signature_b64 = Base64.urlsafe_encode64(signature, padding: false)

    # Token final: payload.signature
    sso_token = "#{payload_b64}.#{signature_b64}"

    redirect_to "#{PORTAL_URL}/sso-callback?token=#{sso_token}", allow_other_host: true
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
