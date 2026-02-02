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
    discount_percent = calculate_discount_percent(approved_proposal)
    
    {
      # Campos obrigatórios
      codigo: @order_service.code,
      numeroOrdemServico: @order_service.code, # Usa o mesmo código
      dataReferencia: @order_service.created_at&.iso8601,
      clienteNomeFantasia: @order_service.client&.fantasy_name || @order_service.client&.social_name,
      fornecedorNomeFantasia: approved_proposal.provider&.fantasy_name || approved_proposal.provider&.social_name,
      tipoServicoSolicitado: @order_service.order_service_type&.name,
      tipo: get_tipo,
      centroCusto: @order_service.cost_center&.name,
      
      # Campos opcionais - Identificação
      subunidade: @order_service.sub_unit&.name || '',
      placa: @order_service.vehicle&.board || '',
      veiculo: get_vehicle_description || '',
      contrato: get_contract_number,
      
      # Campos opcionais - Valores sem desconto
      valorPecasSemDesconto: parts_value,
      valorServicoSemDesconto: services_value,
      
      # Campos opcionais - Desconto
      descontoPercentual: discount_percent,
      descontoPecasPerc: discount_percent, # Mesmo desconto para peças
      descontoServicoPerc: discount_percent, # Mesmo desconto para serviços
      
      # Campos opcionais - Valores com desconto (calculados)
      valorPecasComDesconto: calculate_value_with_discount(parts_value, discount_percent),
      valorServicoComDesconto: calculate_value_with_discount(services_value, discount_percent),
      valorFinal: calculate_total_value(parts_value, services_value, discount_percent),
      
      # Campos opcionais - Notas fiscais
      notaFiscalPeca: get_invoice_number(approved_proposal, 'peca') || '',
      notaFiscalServico: get_invoice_number(approved_proposal, 'servico') || '',
      
      # Campos opcionais - Empenhos (podem ser individuais ou global)
      contratoEmpenhoPecas: get_commitment_contract('parts'),
      empenhoPecas: get_commitment_number('parts'),
      contratoEmpenhoServicos: get_commitment_contract('services'),
      empenhoServicos: get_commitment_number('services'),
      
      # Campos opcionais - Observações
      observacoes: @order_service.details.to_s
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
    
    # Soma todos os itens (peças e serviços) sem desconto
    # Não há distinção entre peças e serviços nos items
    total = proposal.order_service_proposal_items.sum do |item|
      (item.total_value_without_discount || item.total_value || 0).to_f
    end
    
    total.round(2)
  end

  def calculate_services_value(proposal)
    # No sistema atual, não há separação entre peças e serviços
    # Todos estão em order_service_proposal_items
    # Retorna 0 e deixa tudo em valorPecasSemDesconto
    0.0
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

  def get_invoice_number(proposal, tipo)
    return nil unless proposal
    
    # Busca a primeira nota fiscal do tipo (se houver algum campo para distinguir)
    # Como não vimos distinção, retorna o número da primeira nota ou nil
    invoice = proposal.order_service_invoices.first
    invoice&.number
  end

  def get_contract_number
    # Busca número do contrato vinculado aos empenhos
    # Prioriza contrato de peças, depois serviços
    if @order_service.commitment_parts_id.present?
      commitment = Commitment.find_by(id: @order_service.commitment_parts_id)
      return commitment&.contract&.code
    end
    
    if @order_service.commitment_services_id.present?
      commitment = Commitment.find_by(id: @order_service.commitment_services_id)
      return commitment&.contract&.code
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
