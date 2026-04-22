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
    elsif @current_user.client?
      load_client_stats
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

  # === Admin: Webhook Logs ===

  def webhook_logs
    authorize :financial_portal, :webhook_logs?

    @filter = params[:filter] || 'failed'
    scope = WebhookLog.includes(order_service: [:client, :order_service_status, { order_service_proposals: :provider }])

    case @filter
    when 'failed'
      scope = scope.failed
    when 'pending'
      scope = scope.pending
    when 'success'
      scope = scope.success
    when 'skipped'
      scope = scope.skipped
    when 'not_synced'
      scope = scope.not_success
    when 'all'
      # no filter
    else
      scope = scope.not_success
    end

    # Search filters
    if params[:search_os].present?
      os_ids = OrderService.unscoped.where("order_services.code LIKE ?", "%#{params[:search_os]}%").pluck(:id)
      scope = scope.where(order_service_id: os_ids)
    end
    if params[:search_client].present?
      client_ids = User.where("fantasy_name LIKE :q OR social_name LIKE :q", q: "%#{params[:search_client]}%").pluck(:id)
      os_ids = OrderService.unscoped.where(client_id: client_ids).pluck(:id)
      scope = scope.where(order_service_id: os_ids)
    end
    if params[:search_provider].present?
      provider_ids = User.where("fantasy_name LIKE :q OR social_name LIKE :q", q: "%#{params[:search_provider]}%").pluck(:id)
      os_ids = OrderService.unscoped.joins(order_service_proposals: :provider)
                           .where(order_service_proposals: { provider_id: provider_ids })
                           .pluck(:id).uniq
      scope = scope.where(order_service_id: os_ids)
    end

    @webhook_logs = scope.order(last_attempt_at: :desc).page(params[:page]).per(30)

    # Contadores para badges (sem filtros de busca para manter totais globais)
    @failed_count  = WebhookLog.failed.count
    @pending_count = WebhookLog.pending.count
    @success_count = WebhookLog.success.count
    @skipped_count = WebhookLog.skipped.count
    @not_synced_count = @failed_count + @pending_count
  end

  # Verificar sincronização: detecta OS em status pós-autorização que não têm webhook SUCCESS
  def webhook_verify
    authorize :financial_portal, :webhook_logs?

    valid_statuses = [
      OrderServiceStatus::AUTORIZADA_ID,
      OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID,
      OrderServiceStatus::PAGA_ID,
      OrderServiceStatus::NEW_AUTORIZADA_ID,
      8, 9 # Nova numeração: Ag. Pagamento e Paga
    ].uniq

    # OS em status pós-autorização SEM webhook_log OU com webhook_log não-sucesso
    os_without_log = OrderService
      .where(order_service_status_id: valid_statuses)
      .where.not(id: WebhookLog.success.select(:order_service_id))
      .where.not(id: WebhookLog.not_success.select(:order_service_id))

    created = 0
    skipped = 0
    os_without_log.find_each do |os|
      unless os.approved_proposal
        skipped += 1
        next
      end

      WebhookLog.create!(
        order_service_id: os.id,
        status: WebhookLog::FAILED,
        attempts: 0,
        last_error: "Não sincronizada: OS em status #{os.order_service_status&.name} sem registro no Portal Financeiro",
        last_attempt_at: nil
      )
      created += 1
    end

    msg = "Verificação concluída: #{created} OS não sincronizadas encontradas."
    msg += " #{skipped} OS ignoradas (sem proposta aprovada)." if skipped > 0

    redirect_to financial_portal_webhook_logs_path(filter: 'failed'), notice: msg
  end

  # Reenvio síncrono individual — mostra resultado imediato ao admin
  def webhook_resend
    authorize :financial_portal, :webhook_logs?

    log = WebhookLog.find(params[:id])
    os = log.order_service

    # Envia sincronamente para dar feedback imediato ao admin
    result = WebhookFinanceService.send_authorized_os(os.id, resend: true)

    if result[:success]
      redirect_to financial_portal_webhook_logs_path(filter: params[:filter]),
        notice: "OS #{os.code} enviada com sucesso ao Portal Financeiro!"
    else
      # Atualiza o log com o erro para que fique visível na tabela
      log.update(
        status: WebhookLog::FAILED,
        last_error: result[:error].to_s.truncate(255),
        last_attempt_at: Time.current,
        attempts: (log.attempts || 0) + 1
      )
      redirect_to financial_portal_webhook_logs_path(filter: params[:filter]),
        alert: "Falha ao enviar OS #{os.code}: #{result[:error]}"
    end
  end

  def webhook_resend_all
    authorize :financial_portal, :webhook_logs?

    logs = WebhookLog.failed
    count = logs.count
    logs.update_all(status: WebhookLog::PENDING, last_error: nil, updated_at: Time.current)

    logs_to_resend = WebhookLog.pending
    logs_to_resend.each do |log|
      SendAuthorizedOsWebhookJob.perform_later(log.order_service_id, resend: true)
    end

    redirect_to financial_portal_webhook_logs_path(filter: 'pending'),
      notice: "#{count} OS reenviadas para processamento."
  end

  def webhook_skip
    authorize :financial_portal, :webhook_logs?

    log = WebhookLog.find(params[:id])
    os = log.order_service

    log.update!(
      status: WebhookLog::SKIPPED,
      skipped_at: Time.current,
      skipped_reason: params[:reason].presence || "Desconsiderada manualmente"
    )

    redirect_to financial_portal_webhook_logs_path(filter: params[:filter]),
      notice: "OS #{os.code} desconsiderada do envio ao Portal Financeiro."
  end

  private

  def verify_access
    unless @current_user.provider? || @current_user.admin? || @current_user.manager? || @current_user.additional? || @current_user.client?
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

  def load_client_stats
    os_ids = OrderService.where(client_id: @current_user.id).pluck(:id)
    base_scope = OrderServiceProposal.where(order_service_id: os_ids)

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

    @os_recentes = OrderService
      .where(client_id: @current_user.id)
      .where(order_service_status_id: [
        OrderServiceStatus::APROVADA_ID,
        OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID,
        OrderServiceStatus::AUTORIZADA_ID,
        OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID,
        OrderServiceStatus::PAGA_ID
      ])
      .includes(:client, :provider, :vehicle, :order_service_status, :cost_center)
      .order(updated_at: :desc)
      .limit(20)
  end
end
