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
    rejected_ids = @provider.rejected_order_services.pluck(:id)
    
    # 📋 LÓGICA CORRIGIDA:
    # Mostra OS apenas se o fornecedor NÃO tem proposta ativa (não cancelada/reprovada)
    # Filtro por estado do ENDEREÇO do fornecedor vs estados aceitos pelo cliente
    # Isso vale tanto para:
    # - Diagnóstico direcionado (provider_id = fornecedor)
    # - Cotação/Requisição (provider_id IS NULL)
    # - Diagnóstico enviado para cotação (provider_id foi limpo, mas fornecedor original já tem proposta)
    
    if provider_address_state_id.present? && provider_service_types_ids.present?
      scope = OrderService
        .where(order_service_status_id: [OrderServiceStatus::EM_ABERTO_ID, OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID])
      scope = scope.where.not(id: rejected_ids) if rejected_ids.any?
      @os_em_aberto = scope
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
          )
          AND (
            order_services.directed_to_specific_providers = FALSE
            OR order_services.directed_to_specific_providers IS NULL
            OR EXISTS (
              SELECT 1 FROM order_service_directed_providers osdp
              WHERE osdp.order_service_id = order_services.id
              AND osdp.provider_id = ?
            )
          )",
          @provider.id,
          provider_service_types_ids,
          provider_address_state_id,
          @provider.id,
          [
            OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
            OrderServiceProposalStatus::CANCELADA_ID
          ],
          @provider.id
        )
        .includes(:cost_center, :client)
        .order(created_at: :desc)
        .limit(10)
    else
      @os_em_aberto = OrderService.none
    end
    
    @os_em_aberto_count = @os_em_aberto.except(:limit, :offset, :order, :includes).count
    
    # Consolidar contagens de propostas em uma única query
    proposal_counts = OrderServiceProposal.by_provider_id(@provider.id)
      .where(order_service_proposal_status_id: [
        OrderServiceProposalStatus::APROVADA_ID,
        OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID,
        OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
        OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
        OrderServiceProposalStatus::PAGA_ID
      ])
      .group(:order_service_proposal_status_id)
      .count
    
    @propostas_aprovadas_count = proposal_counts[OrderServiceProposalStatus::APROVADA_ID] || 0
    @propostas_aguardando_count = proposal_counts[OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID] || 0
    @propostas_rejeitadas_count = proposal_counts[OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID] || 0
    @propostas_aguardando_pagamento_count = proposal_counts[OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID] || 0
    @propostas_pagas_count = proposal_counts[OrderServiceProposalStatus::PAGA_ID] || 0
    
    # Valor total de propostas aprovadas
    @total_valor_aprovado = OrderServiceProposal.by_provider_id(@provider.id)
      .where(order_service_proposal_status_id: OrderServiceProposalStatus::APROVADA_ID)
      .sum(:total_value)
  end

  # Lista as OSs rejeitadas pelo fornecedor que ainda podem receber propostas
  def rejections
    authorize :provider_dashboard, :rejections?
    
    @provider = @current_user
    
    # OSs rejeitadas que ainda estão em status aberto para propostas
    @rejected_order_services = @provider.rejected_order_services
      .where(order_service_status_id: [
        OrderServiceStatus::EM_ABERTO_ID,
        OrderServiceStatus::EM_REAVALIACAO_ID,
        OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID
      ])
      .includes(:client, :vehicle, :order_service_status, :provider_service_type)
      .order(updated_at: :desc)
      .page(params[:page])
      .per(50)
  end

  # Rejeitar múltiplas OSs de uma vez
  def bulk_reject
    authorize :provider_dashboard, :bulk_reject?
    
    order_service_ids = params[:order_service_ids]
    
    if order_service_ids.blank?
      redirect_to provider_dashboard_index_path, alert: "Nenhuma OS foi selecionada."
      return
    end
    
    @provider = @current_user
    rejected_count = 0
    already_rejected_ids = @provider.rejected_order_services.where(id: order_service_ids).pluck(:id)
    
    # Validar que as OSs estão em status aberto (segurança: não aceitar IDs arbitrários)
    valid_os = OrderService
      .where(id: order_service_ids)
      .where(order_service_status_id: [OrderServiceStatus::EM_ABERTO_ID, OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID])
      .where.not(id: already_rejected_ids)
    
    valid_os.each do |os|
      @provider.rejected_order_services << os
      rejected_count += 1
    end
    
    if rejected_count > 0
      redirect_to provider_dashboard_index_path, notice: "#{rejected_count} OS(s) rejeitada(s) com sucesso."
    else
      redirect_to provider_dashboard_index_path, alert: "Nenhuma OS foi rejeitada."
    end
  end

  # Reverter rejeição de uma OS
  def revert_rejection
    authorize :provider_dashboard, :revert_rejection?
    
    os_id = params[:order_service_id]
    os = OrderService.find_by(id: os_id)
    
    if os.nil?
      redirect_to rejections_provider_dashboard_path, alert: "OS não encontrada."
      return
    end
    
    @provider = @current_user
    
    if @provider.rejected_order_services.exists?(os.id)
      @provider.rejected_order_services.delete(os)
      redirect_to rejections_provider_dashboard_path, notice: "Rejeição revertida com sucesso! Você pode enviar propostas para esta OS novamente."
    else
      redirect_to rejections_provider_dashboard_path, alert: "Esta OS não estava rejeitada por você."
    end
  end

  private

  def verify_provider_access
    unless @current_user.provider?
      redirect_to root_path, alert: "Acesso negado. Apenas fornecedores podem acessar esta página."
    end
  end
end
