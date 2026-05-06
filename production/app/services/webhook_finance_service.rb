# Serviço para enviar webhooks de OS autorizadas para o sistema financeiro
class WebhookFinanceService
  WEBHOOK_URL = 'https://portal-finance.onrender.com/api/webhook/frota/receber-os'.freeze
  WEBHOOK_TOKEN = '30bfff7ce392036b19d87dd6336c6e326d5312b943e01e3e8926c7aa22136b14'.freeze
  TIMEOUT = 10 # segundos

  def self.send_authorized_os(order_service_id, resend: false)
    new(order_service_id, resend: resend).send_webhook
  end

  def initialize(order_service_id, resend: false)
    @resend = resend
    @order_service = OrderService.includes(
      :client,
      :provider,
      :order_service_type,
      :cost_center,
      :sub_unit,
      :vehicle,
      order_service_proposals: [:order_service_proposal_items, :order_service_invoices]
    ).find_by(id: order_service_id)
  end

  def send_webhook
    return { success: false, error: 'OS não encontrada' } unless @order_service
    unless authorized? || (@resend && resendable?)
      return { success: false, error: "OS não está em status válido para envio (status atual: #{@order_service.order_service_status_id})" }
    end
    
    approved_proposal = @order_service.approved_proposal
    return { success: false, error: 'OS sem proposta aprovada' } unless approved_proposal
    if @order_service.locks_out_proposal?(approved_proposal)
      return { success: false, error: 'Fornecedor da proposta em destaque diverge do fornecedor vinculado à OS; corrija antes de enviar ao financeiro.' }
    end
    return { success: false, error: 'Proposta aprovada sem fornecedor cadastrado' } unless approved_proposal.provider_id.present?
    
    # Valida se o fornecedor tem nome cadastrado
    provider = approved_proposal.provider
    unless provider && (provider.fantasy_name.presence || provider.social_name.presence)
      Rails.logger.warn "[WebhookFinance] OS #{@order_service.code} não pode ser enviada: fornecedor sem nome cadastrado (ID: #{provider&.id})"
      return { success: false, error: 'Fornecedor sem nome cadastrado' }
    end

    begin
      response = send_request
      result = handle_response(response)
      update_webhook_log(result, response.code.to_s)
      result
    rescue StandardError => e
      log_error(e)
      result = { success: false, error: e.message }
      update_webhook_log(result, nil)
      result
    end
  end

  private

  def authorized?
    # Suporta AMBOS os IDs para compatibilidade com renumeração: antigo=5, novo=7
    [OrderServiceStatus::AUTORIZADA_ID, OrderServiceStatus::NEW_AUTORIZADA_ID].include?(@order_service.order_service_status_id)
  end

  # Status válidos para reenvio: OS que já passou por Autorizada e avançou no fluxo
  # Inclui Autorizada (5/7), Ag. Pagamento (6/8) e Paga (7/9) em ambas numerações
  def resendable?
    [
      OrderServiceStatus::AUTORIZADA_ID,          # 5 (antigo)
      OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID, # 6 (antigo)
      OrderServiceStatus::PAGA_ID,                 # 7 (antigo)
      OrderServiceStatus::NEW_AUTORIZADA_ID,       # 7 (novo)
      8, 9 # Ag. Pagamento e Paga na nova numeração
    ].uniq.include?(@order_service.order_service_status_id)
  end

  def send_request
    uri = URI(WEBHOOK_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = TIMEOUT
    http.read_timeout = TIMEOUT

    request = Net::HTTP::Post.new(uri.path, headers)
    json_body = force_utf8_hash(payload).to_json
    request.body = json_body.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')

    Rails.logger.info "[WebhookFinance] Enviando OS #{@order_service.code} para #{WEBHOOK_URL}"
    
    http.request(request)
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'X-Webhook-Token' => WEBHOOK_TOKEN
    }
  end

  def payload
    approved_proposal = @order_service.approved_proposal
    parts_value = calculate_parts_value(approved_proposal)
    services_value = calculate_services_value(approved_proposal)
    discount_parts_percent = calculate_discount_parts_percent(approved_proposal)
    discount_services_percent = calculate_discount_services_percent(approved_proposal)
    
    {
      # Campos obrigatórios
      codigo: utf8(@order_service.code),
      clienteNomeFantasia: utf8(@order_service.client&.fantasy_name || @order_service.client&.social_name).strip,
      fornecedorNomeFantasia: utf8(get_provider_name(approved_proposal)).strip,
      tipoServicoSolicitado: utf8(@order_service.order_service_type&.name),
      tipo: utf8(get_tipo),
      centroCusto: utf8(@order_service.cost_center&.name),
      
      # Campos opcionais - Informações Básicas
      numeroOrdemServico: utf8(@order_service.code),
      dataReferencia: get_authorization_date&.strftime('%Y-%m-%d'),
      subunidade: utf8(@order_service.sub_unit&.name || ''),
      placa: utf8(@order_service.vehicle&.board || ''),
      veiculo: utf8(get_vehicle_description || ''),
      observacoes: utf8(@order_service.details.to_s.presence || ''),
      
      # Campos de Valores - OPÇÃO 2: Detalhada (separando peças e serviços)
      valorPecasSemDesconto: parts_value,
      valorServicoSemDesconto: services_value,
      descontoPecasPerc: discount_parts_percent,
      descontoServicoPerc: discount_services_percent,
      valorPecasComDesconto: calculate_value_with_discount(parts_value, discount_parts_percent),
      valorServicoComDesconto: calculate_value_with_discount(services_value, discount_services_percent),
      valorFinal: calculate_total_value_final(approved_proposal),
      
      # Notas Fiscais separadas por tipo
      notaFiscalPeca: utf8(get_invoice_numbers_by_type(approved_proposal, OrderServiceInvoiceType::PECAS_ID)),
      notaFiscalServico: utf8(get_invoice_numbers_by_type(approved_proposal, OrderServiceInvoiceType::SERVICOS_ID)),
      
      # Contratos e Empenhos separados para Peças e Serviços
      contrato: utf8(get_contract_number),
      contratoEmpenhoPecas: utf8(get_commitment_contract('parts')),
      empenhoPecas: utf8(get_commitment_number('parts')),
      contratoEmpenhoServicos: utf8(get_commitment_contract('services')),
      empenhoServicos: utf8(get_commitment_number('services'))
    }
  end

  def get_tipo
    # Determina o tipo baseado nos empenhos vinculados (commitment)
    # Se tem commitment_parts_id: Peças
    # Se tem commitment_services_id: Serviços  
    # Se tem ambos ou nenhum: Global
    
    has_parts = @order_service.commitment_parts_id.present?
    has_services = @order_service.commitment_services_id.present?
    
    return 'Peças' if has_parts && !has_services
    return 'Serviços' if has_services && !has_parts
    'Global'
  end

  def get_provider_name(proposal)
    return '' unless proposal&.provider
    
    provider = proposal.provider
    name = provider.fantasy_name.presence || provider.social_name.presence || provider.email
    name.to_s
  end

  def get_authorization_date
    # Tenta buscar a data do audit quando mudou para status Autorizada
    # Suporta AMBOS os IDs (antigo=5, novo=7) para compatibilidade com renumeração
    autorizada_ids = [OrderServiceStatus::AUTORIZADA_ID, OrderServiceStatus::NEW_AUTORIZADA_ID].uniq
    
    # Primeiro tenta buscar pelo associated_id (mais confiável - preenchido por generate_historic)
    authorization_audit = Audited::Audit
      .where(auditable_type: 'OrderService', auditable_id: @order_service.id, action: 'update')
      .where(associated_id: autorizada_ids)
      .order(created_at: :desc)
      .first
    
    return authorization_audit.created_at if authorization_audit

    # Fallback: busca pelo audited_changes (para audits antigos ou automáticos)
    authorization_audit = Audited::Audit
      .where(auditable_type: 'OrderService', auditable_id: @order_service.id, action: 'update')
      .order(created_at: :asc)
      .find do |audit|
        changes = YAML.load(audit.audited_changes) rescue {}
        autorizada_ids.include?(changes.dig('order_service_status_id', 1))
      end
    
    return authorization_audit.created_at if authorization_audit
    
    # Caso contrário, usa o updated_at da OS (fallback)
    @order_service.updated_at
  end

  def get_vehicle_description
    vehicle = @order_service.vehicle
    return nil unless vehicle
    
    parts = []
    parts << vehicle.brand if vehicle.brand.present?
    parts << vehicle.model if vehicle.model.present?
    parts << vehicle.year if vehicle.year.present?
    
    parts.any? ? parts.join(' ') : vehicle.board
  end

  def calculate_parts_value(proposal)
    return 0.0 unless proposal
    
    # Soma apenas itens da categoria PEÇAS (category_id = 1)
    total = proposal.order_service_proposal_items.sum do |item|
      category_id = item.get_category_id
      if category_id == Category::SERVICOS_PECAS_ID
        (item.total_value_without_discount || item.total_value || 0).to_f
      else
        0.0
      end
    end
    
    total.round(2)
  end

  def calculate_services_value(proposal)
    return 0.0 unless proposal
    
    # Soma apenas itens da categoria SERVIÇOS (category_id = 2)
    total = proposal.order_service_proposal_items.sum do |item|
      category_id = item.get_category_id
      if category_id == Category::SERVICOS_SERVICOS_ID
        (item.total_value_without_discount || item.total_value || 0).to_f
      else
        0.0
      end
    end
    
    total.round(2)
  end

  def calculate_discount_parts_percent(proposal)
    return 0.0 unless proposal
    
    # Calcula desconto específico de peças
    parts_without_discount = 0.0
    parts_discount = 0.0
    
    proposal.order_service_proposal_items.each do |item|
      category_id = item.get_category_id
      if category_id == Category::SERVICOS_PECAS_ID
        parts_without_discount += (item.total_value_without_discount || item.total_value || 0).to_f
        parts_discount += (item.discount || 0).to_f
      end
    end
    
    return 0.0 if parts_without_discount == 0
    
    percent = (parts_discount / parts_without_discount) * 100
    percent.round(2)
  end

  def calculate_discount_services_percent(proposal)
    return 0.0 unless proposal
    
    # Calcula desconto específico de serviços
    services_without_discount = 0.0
    services_discount = 0.0
    
    proposal.order_service_proposal_items.each do |item|
      category_id = item.get_category_id
      if category_id == Category::SERVICOS_SERVICOS_ID
        services_without_discount += (item.total_value_without_discount || item.total_value || 0).to_f
        services_discount += (item.discount || 0).to_f
      end
    end
    
    return 0.0 if services_without_discount == 0
    
    percent = (services_discount / services_without_discount) * 100
    percent.round(2)
  end

  def calculate_discount_percent(proposal)
    return 0.0 unless proposal
    
    # Se houver total_value_without_discount e total_discount, calcula percentual
    if proposal.total_value_without_discount.to_f > 0 && proposal.total_discount.to_f > 0
      percent = (proposal.total_discount.to_f / proposal.total_value_without_discount.to_f) * 100
      return percent.round(2)
    end
    
    0.0
  end

  def get_invoice_numbers_by_type(proposal, invoice_type_id)
    return '' unless proposal
    
    # Busca todas as notas fiscais do tipo especificado e junta com vírgula
    invoices = proposal.order_service_invoices.where(order_service_invoice_type_id: invoice_type_id)
    return '' if invoices.empty?
    
    invoices.map { |inv| utf8(inv.number.to_s) }.compact.join(', ')
  end

  def calculate_total_value_final(proposal)
    return 0.0 unless proposal
    
    # Usa o total_value da proposta (já com desconto aplicado)
    proposal.total_value.to_f.round(2)
  end

  def get_contract_number
    # Busca número do contrato vinculado aos empenhos
    # Prioriza contrato de peças, depois serviços
    if @order_service.commitment_parts_id.present?
      commitment = Commitment.find_by(id: @order_service.commitment_parts_id)
      return commitment&.contract&.number&.to_s || ''
    end
    
    if @order_service.commitment_services_id.present?
      commitment = Commitment.find_by(id: @order_service.commitment_services_id)
      return commitment&.contract&.number&.to_s || ''
    end
    
    ''
  end

  def get_commitment_contract(type)
    # Retorna número do contrato do empenho específico
    commitment_id = type == 'parts' ? @order_service.commitment_parts_id : @order_service.commitment_services_id
    return '' unless commitment_id
    
    commitment = Commitment.find_by(id: commitment_id)
    commitment&.contract&.number&.to_s || ''
  end

  def get_commitment_number(type)
    # Retorna número do empenho específico
    commitment_id = type == 'parts' ? @order_service.commitment_parts_id : @order_service.commitment_services_id
    return '' unless commitment_id
    
    commitment = Commitment.find_by(id: commitment_id)
    commitment&.commitment_number&.to_s || ''
  end

  def calculate_value_with_discount(value, discount_percent)
    return 0.0 if value.to_f == 0
    
    value_with_discount = value.to_f * (1 - (discount_percent.to_f / 100))
    value_with_discount.round(2)
  end

  def calculate_total_value(parts_value, services_value, discount_percent)
    total_without_discount = parts_value.to_f + services_value.to_f
    return 0.0 if total_without_discount == 0
    
    total_with_discount = total_without_discount * (1 - (discount_percent.to_f / 100))
    total_with_discount.round(2)
  end

  def handle_response(response)
    response_body = response.body.to_s.force_encoding('UTF-8').scrub('?')
    case response.code.to_i
    when 200, 201
      body = JSON.parse(response_body) rescue {}
      Rails.logger.info "[WebhookFinance] Sucesso OS #{@order_service.code}: #{body['message']}"
      { success: true, response: body }
    when 401
      Rails.logger.error "[WebhookFinance] Erro de autenticação para OS #{@order_service.code}"
      { success: false, error: 'Token de autenticação inválido' }
    else
      Rails.logger.error "[WebhookFinance] Erro #{response.code} para OS #{@order_service.code}: #{response_body}"
      { success: false, error: "HTTP #{response.code}: #{response_body}" }
    end
  end

  def log_error(exception)
    msg = exception.message.to_s.force_encoding('UTF-8').scrub('?')
    Rails.logger.error "[WebhookFinance] Exceção ao enviar OS #{@order_service.code}: #{exception.class} - #{msg}"
    Rails.logger.error exception.backtrace.join("\n") rescue nil
  end

  def update_webhook_log(result, http_code)
    return unless @order_service
    log = WebhookLog.find_or_initialize_by(order_service_id: @order_service.id)
    log.attempts = (log.attempts || 0) + 1
    log.last_attempt_at = Time.current
    log.last_http_code = http_code
    if result[:success]
      log.status = WebhookLog::SUCCESS
      log.succeeded_at = Time.current
      log.last_error = nil
    else
      log.last_error = result[:error].to_s.truncate(255)
      # Marca como falha somente se ultrapassou as tentativas do job (3)
      log.status = WebhookLog::FAILED if log.attempts >= 3
    end
    log.save
  rescue => e
    Rails.logger.error "[WebhookFinance] Erro ao salvar WebhookLog: #{e.message}"
  end

  # Converte valor para string UTF-8 segura
  def utf8(val)
    return val unless val.is_a?(String)
    val.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
  rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
    val.force_encoding('UTF-8').scrub('?')
  end

  # Força encoding UTF-8 em todos os valores string de um hash (recursivo)
  def force_utf8_hash(hash)
    hash.transform_values do |v|
      case v
      when String
        v.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
      when Hash
        force_utf8_hash(v)
      when Array
        v.map { |item| item.is_a?(String) ? item.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') : item }
      else
        v
      end
    end
  end
end
