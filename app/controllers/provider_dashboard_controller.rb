class ProviderDashboardController < ApplicationController
  before_action :verify_provider_access

  def index
    authorize :provider_dashboard, :index?
    
    # Dados do fornecedor atual
    @provider = @current_user
    
    # Propostas do fornecedor - usando query direta pelo provider_id
    @proposals_em_cadastro = OrderServiceProposal.by_provider_id(@provider.id)
      .where(order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID)
      .includes(:order_service)
      .order(created_at: :desc)
      .limit(10)
    
    @proposals_aguardando = OrderServiceProposal.by_provider_id(@provider.id)
      .where(order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID)
      .includes(:order_service)
      .order(created_at: :desc)
      .limit(10)
    
    @proposals_aprovadas = OrderServiceProposal.by_provider_id(@provider.id)
      .where(order_service_proposal_status_id: OrderServiceProposalStatus::APROVADA_ID)
      .not_complement
      .includes(:order_service)
      .order(created_at: :desc)
      .limit(10)
    
    # Estatísticas
    # OSs em aberto (disponíveis para o fornecedor responder - SEM proposta ativa ainda)
    provider_address_state_id = @provider.address&.state_id
    provider_service_types_ids = @provider.provider_service_types.pluck(:id).uniq
    rejected_ids = @provider.rejected_order_services.map(&:id)
    
    # 📋 LÓGICA CORRIGIDA:
    # Mostra OS apenas se o fornecedor NÃO tem proposta ativa (não cancelada/reprovada)
    # Filtro por estado do ENDEREÇO do fornecedor vs estados aceitos pelo cliente
    # Isso vale tanto para:
    # - Diagnóstico direcionado (provider_id = fornecedor)
    # - Cotação/Requisição (provider_id IS NULL)
    # - Diagnóstico enviado para cotação (provider_id foi limpo, mas fornecedor original já tem proposta)
    
    if provider_address_state_id.present? && provider_service_types_ids.present?
      @os_em_aberto = OrderService
        .where(order_service_status_id: [OrderServiceStatus::EM_ABERTO_ID, OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID])
        .where.not(id: rejected_ids)
        .where(
          "(
            order_services.provider_id = ? OR order_services.provider_id IS NULL
          )
          AND order_services.provider_service_type_id IN (?)
          AND EXISTS (
            SELECT 1 FROM states_users su 
            INNER JOIN users u ON u.id = su.user_id
            WHERE su.state_id = ? 
            AND u.id = order_services.client_id
          )
          AND NOT EXISTS (
            SELECT 1 FROM order_service_proposals osp 
            WHERE osp.order_service_id = order_services.id 
            AND osp.provider_id = ? 
            AND osp.order_service_proposal_status_id NOT IN (?)
          )",
          @provider.id,
          provider_service_types_ids,
          provider_address_state_id,
          @provider.id,
          [
            OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
            OrderServiceProposalStatus::CANCELADA_ID
          ]
        )
        .includes(:cost_center, :client)
        .order(created_at: :desc)
        .limit(10)
    else
      @os_em_aberto = OrderService.none
    end
    
    @os_em_aberto_count = @os_em_aberto.size
    
    @propostas_aprovadas_count = OrderServiceProposal.by_provider_id(@provider.id)
      .where(order_service_proposal_status_id: OrderServiceProposalStatus::APROVADA_ID).count
    
    @propostas_aguardando_count = OrderServiceProposal.by_provider_id(@provider.id)
      .where(order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID).count
    
    @propostas_rejeitadas_count = OrderServiceProposal.by_provider_id(@provider.id)
      .where(order_service_proposal_status_id: OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID).count
    
    # Propostas aguardando pagamento
    @propostas_aguardando_pagamento_count = OrderServiceProposal.by_provider_id(@provider.id)
      .where(order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID).count
    
    # Propostas pagas
    @propostas_pagas_count = OrderServiceProposal.by_provider_id(@provider.id)
      .where(order_service_proposal_status_id: OrderServiceProposalStatus::PAGA_ID).count
    
    # Valor total de propostas aprovadas
    @total_valor_aprovado = OrderServiceProposal.by_provider_id(@provider.id)
      .where(order_service_proposal_status_id: OrderServiceProposalStatus::APROVADA_ID)
      .sum(:total_value)
  end

  private

  def verify_provider_access
    unless @current_user.provider?
      redirect_to root_path, alert: "Acesso negado. Apenas fornecedores podem acessar esta página."
    end
  end
end
