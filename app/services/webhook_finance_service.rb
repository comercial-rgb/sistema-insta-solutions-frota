# Serviço para enviar webhooks de OS autorizadas para o sistema financeiro
class WebhookFinanceService
  WEBHOOK_URL = 'https://portal-finance-api.onrender.com/api/webhook/frota/receber-os'.freeze
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
      order_service_proposals: [:order_service_proposal_items]
    ).find_by(id: order_service_id)
  end

  def send_webhook
    return { success: false, error: 'OS não encontrada' } unless @order_service
    return { success: false, error: 'OS não está no status Autorizada' } unless authorized?

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
    
    {
      codigo: @order_service.code,
      clienteNomeFantasia: @order_service.client&.fantasy_name || @order_service.client&.social_name,
      fornecedorNomeFantasia: @order_service.provider&.fantasy_name || @order_service.provider&.social_name,
      tipoServicoSolicitado: @order_service.order_service_type&.name,
      tipo: get_tipo,
      centroCusto: @order_service.cost_center&.name,
      dataReferencia: @order_service.created_at&.iso8601,
      subunidade: @order_service.sub_unit&.name,
      placa: @order_service.vehicle&.board,
      veiculo: get_vehicle_description,
      valorPecasSemDesconto: calculate_parts_value(approved_proposal),
      valorServicoSemDesconto: calculate_services_value(approved_proposal),
      descontoPercentual: approved_proposal&.discount_percent || 0,
      notaFiscalPeca: approved_proposal&.invoice_parts_number,
      notaFiscalServico: approved_proposal&.invoice_services_number
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
    parts << vehicle.vehicle_brand&.name if vehicle.vehicle_brand
    parts << vehicle.vehicle_model&.name if vehicle.vehicle_model
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
