class FaturamentoController < ApplicationController
  before_action :verify_access

  def index
    authorize :faturamento, :index?

    # Resumo (KPI data)
    @resumo = calcular_resumo

    # Faturas list with filters
    @faturas = Fatura.includes(:client, :cost_center, :contract)
    @faturas = @faturas.where(client_id: @current_user.id) if @current_user.client?
    @faturas = apply_filters(@faturas)
    @faturas = @faturas.order(created_at: :desc).page(params[:page]).per(25)

    # Últimas faturas (resumo tab)
    @ultimas_faturas = Fatura.order(created_at: :desc).limit(5)

    # Clients & cost_centers for filter dropdowns
    @clients = User.client.active.name_ordered
    @cost_centers = CostCenter.order(:name)

    # Alertas de faturas vencidas (para admin/manager)
    @faturas_vencidas = Fatura.vencidas.includes(:client).order(:data_vencimento) if @current_user.admin? || @current_user.manager?

    respond_to do |format|
      format.html
      format.json { render json: faturas_json }
    end
  end

  def show
    authorize :faturamento, :show?
    @fatura = Fatura.includes(:fatura_itens, :client, :cost_center, :contract).find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: fatura_detail_json(@fatura) }
    end
  end

  def create
    authorize :faturamento, :create?

    client = User.find(params[:client_id])
    os_ids = Array(params[:order_service_ids]).map(&:to_i).uniq

    # Somente OS que estão ATUALMENTE no status Autorizada (ID 5) e não faturadas
    order_services = OrderService.where(id: os_ids, client_id: client.id, invoiced: false)
                                 .where(order_service_status_id: OrderServiceStatus::AUTORIZADA_ID)

    if order_services.empty?
      respond_to do |format|
        format.html { redirect_to faturamento_index_path, alert: 'Nenhuma OS válida selecionada.' }
        format.json { render json: { error: 'Nenhuma OS válida selecionada.' }, status: :unprocessable_entity }
      end
      return
    end

    cost_center = order_services.first.cost_center
    sub_unit = order_services.first.sub_unit

    # Calculate totals from OS proposals
    total_bruto = 0
    items_data = []

    order_services.each do |os|
      proposal = find_approved_proposal(os)
      next unless proposal

      os_value = proposal.total_value.to_f
      total_bruto += os_value

      items_data << {
        order_service_id: os.id,
        order_service_proposal_id: proposal.id,
        descricao: "OS ##{os.code} - #{os.vehicle&.board}",
        tipo: 'servico',
        valor: os_value,
        quantidade: 1,
        veiculo_placa: os.vehicle&.board,
        centro_custo_nome: os.cost_center&.name
      }
    end

    # Tipo de valor: bruto (antes do desconto) ou liquido (após desconto)
    tipo_valor = params[:tipo_valor].presence || 'bruto'
    aplicar_retencao = params[:aplicar_retencao] != false && params[:aplicar_retencao] != 'false'

    # Calculate discount and retentions based on client sphere
    client_discount_pct = client.discount_percent.to_f
    desconto_valor = total_bruto * (client_discount_pct / 100)

    # Calcular retenções conforme Config Impostos:
    #   Optante Simples Nacional: ISENTO (0%)
    #   Não-simples + Federal:   Peças 5,85% (IR 1,2% + CSLL 1% + PIS 0,65% + Cofins 3%)
    #                            Serviços 9,45% (IR 4,8% + CSLL 1% + PIS 0,65% + Cofins 3%)
    #   Não-simples + Mun/Est:   Peças 1,20% (somente IR)
    #                            Serviços 4,80% (somente IR)
    is_federal = client.federal?
    total_retencao = 0.0

    order_services.each do |os|
      prop = find_approved_proposal(os)
      next unless prop
      next if prop.provider&.optante_simples  # Simples = ISENTO

      invoices = prop.order_service_invoices.to_a
      sum_parts = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::PECAS_ID }.sum(&:value).to_f
      sum_services = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::SERVICOS_ID }.sum(&:value).to_f

      if is_federal
        total_retencao += sum_parts * 0.0585    # 5,85%
        total_retencao += sum_services * 0.0945 # 9,45%
      else
        total_retencao += sum_parts * 0.012     # 1,20% (somente IR)
        total_retencao += sum_services * 0.048  # 4,80% (somente IR)
      end
    end

    # Zerar retenções se usuário desabilitou
    total_retencao = 0.0 unless aplicar_retencao

    valor_liquido = total_bruto - desconto_valor
    valor_final = valor_liquido - total_retencao

    # Build fatura
    vencimento = params[:vencimento].present? ? Date.parse(params[:vencimento]) : (Date.current + 30.days)
    @fatura = Fatura.new(
      numero: Fatura.gerar_numero,
      client_id: client.id,
      cost_center_id: cost_center&.id,
      sub_unit_id: sub_unit&.id,
      data_emissao: Date.current,
      data_vencimento: vencimento,
      status: 'aberta',
      valor_bruto: total_bruto,
      desconto: desconto_valor,
      total_retencoes: total_retencao.round(2),
      valor_liquido: valor_liquido.round(2),
      valor_final: valor_final.round(2),
      tipo_valor: tipo_valor,
      total_itens: items_data.size,
      observacoes: params[:observacoes]
    )

    ActiveRecord::Base.transaction do
      @fatura.save!

      items_data.each { |item| @fatura.fatura_itens.create!(item) }

      # Mark OS as invoiced and move to "Aguardando pagamento"
      aguardando_pagamento_id = OrderServiceStatus.find_by(name: 'Aguardando pagamento')&.id ||
                                 OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID
      order_services.update_all(
        invoiced: true,
        invoiced_at: Time.current,
        order_service_status_id: aguardando_pagamento_id
      )
    end

    # Generate DOCX
    docx_path = nil
    begin
      current_month = Date.current.beginning_of_month..Date.current.end_of_month
      service = Utils::OrderServices::GenerateInvoiceDocxService.new(
        order_services.to_a, client, current_month, tipo_valor: tipo_valor
      )
      docx_path = service.call
      docx_filename = File.basename(docx_path) if docx_path
    rescue => e
      Rails.logger.error "Erro ao gerar DOCX: #{e.message}"
      docx_filename = nil
    end

    respond_to do |format|
      format.html { redirect_to faturamento_path(@fatura), notice: "Fatura #{@fatura.numero} criada com sucesso!" }
      format.json { render json: { success: true, fatura_id: @fatura.id, numero: @fatura.numero, docx_url: docx_filename ? "/#{docx_filename}" : nil } }
    end

  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html { redirect_to faturamento_index_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  def update
    authorize :faturamento, :update?
    @fatura = Fatura.find(params[:id])

    if @fatura.update(fatura_update_params)
      @fatura.calcular_retencoes!
      @fatura.save!
      respond_to do |format|
        format.html { redirect_to faturamento_path(@fatura), notice: 'Fatura atualizada com sucesso!' }
        format.json { render json: { success: true, fatura: @fatura } }
      end
    else
      respond_to do |format|
        format.html { redirect_to faturamento_path(@fatura), alert: @fatura.errors.full_messages.join(', ') }
        format.json { render json: { error: @fatura.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def cobrar
    authorize :faturamento, :update?
    @fatura = Fatura.find(params[:id])

    if @fatura.status != 'aberta'
      respond_to do |format|
        format.html { redirect_to faturamento_index_path, alert: "Fatura já está #{@fatura.status}, não pode gerar cobrança." }
        format.json { render json: { error: "Fatura já está #{@fatura.status}" }, status: :bad_request }
      end
      return
    end

    @fatura.update!(status: 'enviada', data_envio_empresa: Date.current)

    respond_to do |format|
      format.html { redirect_to faturamento_index_path, notice: 'Cobrança gerada! Status: Enviada.' }
      format.json { render json: { success: true } }
    end
  end

  def marcar_pago
    authorize :faturamento, :update?
    @fatura = Fatura.find(params[:id])

    unless %w[aberta enviada].include?(@fatura.status)
      respond_to do |format|
        format.json { render json: { error: "Fatura está #{@fatura.status}, não pode ser marcada como paga." }, status: :bad_request }
      end
      return
    end

    @fatura.update!(
      status: 'paga',
      data_pagamento: params[:data_pagamento].presence || Date.current,
      pago_por_id: @current_user.id
    )

    respond_to do |format|
      format.html { redirect_to faturamento_path(@fatura), notice: 'Fatura marcada como paga!' }
      format.json { render json: { success: true } }
    end
  end

  def gerar_docx
    authorize :faturamento, :show?
    @fatura = Fatura.includes(:fatura_itens, :client).find(params[:id])
    os_ids = @fatura.fatura_itens.where.not(order_service_id: nil).pluck(:order_service_id)
    order_services = OrderService.where(id: os_ids)

    current_month = (@fatura.data_emissao || Date.current).beginning_of_month..(@fatura.data_emissao || Date.current).end_of_month
    service = Utils::OrderServices::GenerateInvoiceDocxService.new(
      order_services.to_a, @fatura.client, current_month
    )
    docx_path = service.call

    send_file docx_path, filename: "fatura_#{@fatura.numero}.docx",
              type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
              disposition: 'attachment'
  rescue => e
    redirect_to faturamento_path(@fatura), alert: "Erro ao gerar documento: #{e.message}"
  end

  # JSON: OS em aberto para um cliente
  def os_abertos_json
    authorize :faturamento, :abertos?
    client_id = params[:client_id]

    unless client_id.present?
      render json: { results: [] }
      return
    end

    # Somente OS que estão ATUALMENTE no status Autorizada (ID 5)
    os_scope = OrderService.not_invoiced
                           .where(client_id: client_id)
                           .where(order_service_status_id: OrderServiceStatus::AUTORIZADA_ID)
                           .includes(:vehicle, :order_service_proposals, :cost_center, :sub_unit)

    # Filtro por período de apuração (data de criação da OS)
    if params[:data_inicio].present?
      os_scope = os_scope.where('order_services.created_at >= ?', Date.parse(params[:data_inicio]).beginning_of_day)
    end
    if params[:data_fim].present?
      os_scope = os_scope.where('order_services.created_at <= ?', Date.parse(params[:data_fim]).end_of_day)
    end

    os_scope = os_scope.by_cost_center_id(params[:cost_center_id]) if params[:cost_center_id].present?

    if params[:sub_unit_id].present?
      os_scope = os_scope.joins(:vehicle).where(vehicles: { sub_unit_id: params[:sub_unit_id] })
    end

    results = os_scope.order(:code).map do |os|
      proposal = find_approved_proposal(os)
      next nil unless proposal

      # NF numbers from proposal invoices
      invoices = proposal.order_service_invoices.to_a
      nf_pecas = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::PECAS_ID }.map(&:number).compact.join(', ')
      nf_servicos = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::SERVICOS_ID }.map(&:number).compact.join(', ')

      # Valores de NF por tipo (mais precisos que total_parts_value/total_services_value)
      nf_parts_value = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::PECAS_ID }.sum(&:value).to_f
      nf_services_value = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::SERVICOS_ID }.sum(&:value).to_f

      # Provider details
      prov = proposal.provider
      provider_name = prov&.fantasy_name.presence || prov&.social_name.presence || prov&.name
      provider_cnpj = prov&.cnpj
      provider_phone = prov&.phone.presence || prov&.cellphone.presence || prov&.get_first_phone_phone
      provider_email = prov&.email
      provider_optante = prov&.optante_simples || false

      # Commitment/Contract info
      commitment_parts = os.commitment_parts
      commitment_services = os.commitment_services
      commitment = commitment_parts || commitment_services || os.commitment
      contract = commitment&.contract

      {
        id: os.id,
        code: os.code,
        vehicle_plate: os.vehicle&.board,
        vehicle_model: os.vehicle&.model,
        cost_center: os.cost_center&.name,
        sub_unit: os.sub_unit&.name,
        provider: provider_name,
        provider_cnpj: provider_cnpj,
        provider_phone: provider_phone,
        provider_email: provider_email,
        provider_optante_simples: provider_optante,
        total_parts: nf_parts_value,
        total_services: nf_services_value,
        total_value: proposal.total_value.to_f,
        nf_pecas: nf_pecas,
        nf_servicos: nf_servicos,
        contract_number: contract&.number,
        contract_name: contract&.name,
        commitment_number: commitment&.commitment_number,
        status: os.order_service_status&.name,
        created_at: os.created_at&.strftime('%d/%m/%Y')
      }
    end.compact

    # Client discount and sphere info
    client = User.find_by(id: client_id)
    client_discount = client&.discount_percent.to_f
    client_sphere = client&.government_sphere.to_i  # 0=Municipal, 1=Estadual, 2=Federal

    # Contracts/empenhos used across these OS
    contract_ids = results.map { |r| r[:contract_number] }.compact.uniq
    commitment_numbers = results.map { |r| r[:commitment_number] }.compact.uniq

    # Saldo do contrato (real consumed)
    contracts_info = []
    Contract.where(client_id: client_id, active: true).includes(:commitments).each do |c|
      total_consumed = 0.0
      c.commitments.each do |cm|
        total_consumed += Commitment.get_total_already_consumed_value(cm).to_f
      end
      saldo_real = c.get_total_value.to_f - total_consumed
      contracts_info << {
        number: c.number,
        name: c.name,
        total: c.get_total_value.to_f,
        consumed: total_consumed,
        saldo: saldo_real
      }
    end

    # Cost centers and sub_units for this client
    client_cost_centers = CostCenter.where(client_id: client_id).order(:name).map { |cc| { id: cc.id, name: cc.name } }

    render json: {
      results: results,
      cost_centers: client_cost_centers,
      client_discount: client_discount,
      client_sphere: client_sphere,
      contracts_info: contracts_info,
      commitment_numbers: commitment_numbers
    }
  end

  # JSON: Sub units for a cost center
  def sub_units_json
    authorize :faturamento, :abertos?
    cost_center_id = params[:cost_center_id]

    sub_units = cost_center_id.present? ? SubUnit.where(cost_center_id: cost_center_id).order(:name) : SubUnit.none

    render json: { sub_units: sub_units.map { |su| { id: su.id, name: su.name } } }
  end

  # JSON endpoints for AJAX tab loading
  def resumo_json
    authorize :faturamento, :resumo?
    render json: { resumo: calcular_resumo, ultimas_faturas: Fatura.order(created_at: :desc).limit(5) }
  end

  def faturas_json_endpoint
    authorize :faturamento, :faturas?
    faturas = Fatura.includes(:client, :cost_center)
    faturas = faturas.where(client_id: @current_user.id) if @current_user.client?
    faturas = apply_filters(faturas)
    page = (params[:page] || 1).to_i
    total = faturas.count
    rows = faturas.order(created_at: :desc).offset((page - 1) * 25).limit(25)

    render json: {
      results: rows.map { |f| fatura_row_json(f) },
      pagination: { page: page, pageSize: 25, total: total, pageCount: (total / 25.0).ceil }
    }
  end

  private

  def find_approved_proposal(order_service)
    approved_statuses = OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES
    order_service.order_service_proposals
      .where(is_complement: [false, nil])
      .where(order_service_proposal_status_id: approved_statuses)
      .order(updated_at: :desc)
      .first
  end

  def calcular_resumo
    faturas = Fatura.all
    faturas = faturas.where(client_id: @current_user.id) if @current_user.client?

    {
      total_faturas: faturas.count,
      total_abertas: faturas.abertas.count,
      valor_abertas: faturas.abertas.sum(:valor_bruto),
      total_enviadas: faturas.enviadas.count,
      valor_enviadas: faturas.enviadas.sum(:valor_bruto),
      total_pagas: faturas.pagas.count,
      valor_pagas: faturas.pagas.sum(:valor_bruto),
      total_canceladas: faturas.canceladas.count,
      total_vencidas: faturas.vencidas.count,
      valor_vencidas: faturas.vencidas.sum(:valor_bruto),
      valor_total_bruto: faturas.sum(:valor_bruto),
      valor_total_liquido: faturas.sum(:valor_liquido)
    }
  end

  def apply_filters(scope)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(client_id: params[:client_id]) if params[:client_id].present?
    scope = scope.where(cost_center_id: params[:cost_center_id]) if params[:cost_center_id].present?
    scope = scope.where('faturas.numero LIKE ?', "%#{params[:search]}%") if params[:search].present?
    scope = scope.where('data_emissao >= ?', params[:data_inicio]) if params[:data_inicio].present?
    scope = scope.where('data_emissao <= ?', params[:data_fim]) if params[:data_fim].present?
    scope
  end

  def fatura_row_json(f)
    {
      id: f.id,
      numero: f.numero,
      cliente: f.client&.fantasy_name.presence || f.client&.social_name.presence || f.client&.name || '-',
      client_id: f.client_id,
      centro_custo: f.cost_center&.name || '-',
      cost_center_id: f.cost_center_id,
      data_emissao: f.data_emissao,
      data_emissao_fmt: f.data_emissao&.strftime('%d/%m/%Y'),
      data_envio_empresa: f.data_envio_empresa,
      data_envio_fmt: f.data_envio_empresa&.strftime('%d/%m/%Y'),
      data_vencimento: f.data_vencimento,
      data_vencimento_fmt: f.data_vencimento&.strftime('%d/%m/%Y'),
      data_pagamento: f.data_pagamento,
      data_pagamento_fmt: f.data_pagamento&.strftime('%d/%m/%Y'),
      status: f.status,
      valor_bruto: f.valor_bruto.to_f,
      desconto: f.desconto.to_f,
      valor_liquido: f.valor_liquido.to_f,
      total_retencoes: f.total_retencoes.to_f,
      taxa_administracao: f.taxa_administracao.to_f,
      nota_fiscal_numero: f.nota_fiscal_numero,
      nota_fiscal_serie: f.nota_fiscal_serie,
      total_itens: f.total_itens
    }
  end

  def fatura_detail_json(f)
    {
      **fatura_row_json(f),
      valor_final: f.valor_final.to_f,
      ir_percentual: f.ir_percentual.to_f,
      pis_percentual: f.pis_percentual.to_f,
      cofins_percentual: f.cofins_percentual.to_f,
      csll_percentual: f.csll_percentual.to_f,
      observacoes: f.observacoes,
      admin_observacoes: f.admin_observacoes,
      prazo_recebimento: f.prazo_recebimento,
      contrato: f.contract&.slice(:id, :name),
      itens: f.fatura_itens.map { |i|
        {
          id: i.id,
          descricao: i.descricao,
          tipo: i.tipo,
          valor: i.valor.to_f,
          quantidade: i.quantidade.to_f,
          veiculo_placa: i.veiculo_placa,
          centro_custo_nome: i.centro_custo_nome,
          order_service_id: i.order_service_id
        }
      }
    }
  end

  def fatura_params
    params.require(:fatura).permit(
      :client_id, :cost_center_id, :contract_id,
      :data_emissao, :data_vencimento, :prazo_recebimento,
      :valor_bruto, :desconto, :ir_percentual, :pis_percentual, :cofins_percentual, :csll_percentual,
      :taxa_administracao, :nota_fiscal_numero, :nota_fiscal_serie,
      :observacoes
    )
  end

  def fatura_update_params
    params.require(:fatura).permit(
      :status, :data_envio_empresa, :data_recebimento, :data_vencimento,
      :admin_observacoes, :nota_fiscal_numero, :nota_fiscal_serie,
      :desconto, :valor_bruto
    )
  end

  def verify_access
    unless @current_user&.admin? || @current_user&.manager? || @current_user&.additional? || @current_user&.provider? || @current_user&.client?
      redirect_to root_path, alert: "Acesso negado."
    end
  end
end
