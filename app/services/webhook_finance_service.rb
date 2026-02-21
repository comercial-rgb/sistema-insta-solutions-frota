# Serviço para enviar webhooks de OS autorizadas para o sistema financeiro
class WebhookFinanceService
  WEBHOOK_URL = 'https://portal-finance.onrender.com/api/webhook/frota/receber-os'.freeze
  WEBHOOK_TOKEN = '30bfff7ce392036b19d87dd6336c6e326d5312b943e01e3e8926c7aa22136b14'.freeze
  TIMEOUT = 10 # segundos

  def self.send_authorized_os(order_service_id)
    new(order_service_id).send_webhook
  end

  def initialize(order_service_id)
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
    return { success: false, error: 'OS não está no status Autorizada' } unless authorized?
    
    approved_proposal = @order_service.approved_proposal
    return { success: false, error: 'OS sem proposta aprovada' } unless approved_proposal
    return { success: false, error: 'Proposta aprovada sem fornecedor cadastrado' } unless approved_proposal.provider_id.present?
    
    # Valida se o fornecedor tem nome cadastrado
    provider = approved_proposal.provider
    unless provider && (provider.fantasy_name.presence || provider.social_name.presence)
      Rails.logger.warn "[WebhookFinance] OS #{@order_service.code} não pode ser enviada: fornecedor sem nome cadastrado (ID: #{provider&.id})"
      return { success: false, error: 'Fornecedor sem nome cadastrado' }
    end

    begin
      response = send_request
      handle_response(response)
    rescue StandardError => e
      log_error(e)
      { success: false, error: e.message }
    end
  end

  private

  def authorized?
    @order_service.order_service_status_id == OrderServiceStatus::AUTORIZADA_ID
  end

  def send_request
    uri = URI(WEBHOOK_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = TIMEOUT
    http.read_timeout = TIMEOUT

    request = Net::HTTP::Post.new(uri.path, headers)
    request.body = payload.to_json

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
      codigo: @order_service.code,
      clienteNomeFantasia: @order_service.client&.fantasy_name || @order_service.client&.social_name,
      fornecedorNomeFantasia: get_provider_name(approved_proposal),
      tipoServicoSolicitado: @order_service.order_service_type&.name,
      tipo: get_tipo,
      centroCusto: @order_service.cost_center&.name,
      
      # Campos opcionais - Informações Básicas
      numeroOrdemServico: @order_service.code,
      dataReferencia: get_authorization_date&.strftime('%Y-%m-%d'),
      subunidade: @order_service.sub_unit&.name || '',
      placa: @order_service.vehicle&.board || '',
      veiculo: get_vehicle_description || '',
      observacoes: @order_service.details.to_s.presence || '',
      
      # Campos de Valores - OPÇÃO 2: Detalhada (separando peças e serviços)
      valorPecasSemDesconto: parts_value,
      valorServicoSemDesconto: services_value,
      descontoPecasPerc: discount_parts_percent,
      descontoServicoPerc: discount_services_percent,
      valorPecasComDesconto: calculate_value_with_discount(parts_value, discount_parts_percent),
      valorServicoComDesconto: calculate_value_with_discount(services_value, discount_services_percent),
      valorFinal: calculate_total_value_final(approved_proposal),
      
      # Notas Fiscais separadas por tipo
      notaFiscalPeca: get_invoice_numbers_by_type(approved_proposal, OrderServiceInvoiceType::PECAS_ID),
      notaFiscalServico: get_invoice_numbers_by_type(approved_proposal, OrderServiceInvoiceType::SERVICOS_ID),
      
      # Contratos e Empenhos separados para Peças e Serviços
      contrato: get_contract_number,
      contratoEmpenhoPecas: get_commitment_contract('parts'),
      empenhoPecas: get_commitment_number('parts'),
      contratoEmpenhoServicos: get_commitment_contract('services'),
      empenhoServicos: get_commitment_number('services')
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
    # Tenta buscar a data do audit quando mudou para status Autorizada (5)
    authorization_audit = Audited::Audit
      .where(auditable_type: 'OrderService', auditable_id: @order_service.id, action: 'update')
      .order(created_at: :asc)
      .find do |audit|
        changes = YAML.load(audit.audited_changes) rescue {}
        changes.dig('order_service_status_id', 1) == 5  # Mudou PARA status 5
      end
    
    # Se encontrou o audit, usa a data dele
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
    
    invoices.map(&:number).compact.join(', ')
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
    commitment&.contract&.code || ''
  end

  def get_commitment_number(type)
    # Retorna número do empenho específico
    commitment_id = type == 'parts' ? @order_service.commitment_parts_id : @order_service.commitment_services_id
    return '' unless commitment_id
    
    commitment = Commitment.find_by(id: commitment_id)
    commitment&.code || ''
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
    case response.code.to_i
    when 200, 201
      body = JSON.parse(response.body) rescue {}
      Rails.logger.info "[WebhookFinance] Sucesso OS #{@order_service.code}: #{body['message']}"
      { success: true, response: body }
    when 401
      Rails.logger.error "[WebhookFinance] Erro de autenticação para OS #{@order_service.code}"
      { success: false, error: 'Token de autenticação inválido' }
    else
      Rails.logger.error "[WebhookFinance] Erro #{response.code} para OS #{@order_service.code}: #{response.body}"
      { success: false, error: "HTTP #{response.code}: #{response.body}" }
    end
  end

  def log_error(exception)
    Rails.logger.error "[WebhookFinance] Exceção ao enviar OS #{@order_service.code}: #{exception.class} - #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
  end
end
