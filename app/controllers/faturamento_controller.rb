class FaturamentoController < ApplicationController
  before_action :verify_access

  def index
    authorize :faturamento, :index?

    # Resumo (KPI data)
    @resumo = calcular_resumo

    # Faturas list with filters
    @faturas = Fatura.includes(:client, :cost_center, :contract)
    @faturas = apply_user_client_scope(@faturas)
    @faturas = apply_filters(@faturas)
    @faturas = @faturas.order(created_at: :desc).page(params[:page]).per(25)

    # Últimas faturas (resumo tab)
    @ultimas_faturas = apply_user_client_scope(Fatura.all)
    @ultimas_faturas = @ultimas_faturas.order(created_at: :desc).limit(5)

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
    scope = Fatura.includes(
      fatura_itens: { order_service: [:vehicle, :cost_center, :sub_unit,
        { order_service_proposals: [:provider, :order_service_invoices] }] },
      client: [], cost_center: [], contract: []
    )
    scope = apply_user_client_scope(scope)
    @fatura = scope.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: fatura_detail_json(@fatura) }
    end
  end

  def create
    authorize :faturamento, :create?

    client = User.find(params[:client_id])
    os_ids = Array(params[:order_service_ids]).map(&:to_i).uniq
    os_observacoes = (params[:os_observacoes] || {}).to_h { |k, v| [k.to_i, v.to_s] }

    # Somente OS em status Autorizada e não faturadas
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
    # NOTA: proposal.total_value já inclui desconto do contrato
    # proposal.total_value_without_discount = valor bruto real
    total_bruto = 0
    total_com_desconto = 0
    total_desconto = 0
    items_data = []

    order_services.each do |os|
      proposal = find_approved_proposal(os)
      next unless proposal

      os_bruto = proposal.total_value_without_discount.to_f
      os_com_desconto = proposal.total_value.to_f
      os_desconto = proposal.total_discount.to_f
      total_bruto += os_bruto
      total_com_desconto += os_com_desconto
      total_desconto += os_desconto

      items_data << {
        order_service_id: os.id,
        order_service_proposal_id: proposal.id,
        descricao: "OS ##{os.code} - #{os.vehicle&.board}",
        tipo: 'servico',
        valor: os_bruto,
        quantidade: 1,
        veiculo_placa: os.vehicle&.board,
        centro_custo_nome: os.cost_center&.name,
        observacoes: os_observacoes[os.id].presence
      }
    end

    # Tipo de valor: bruto (antes do desconto) ou liquido (após desconto)
    tipo_valor = params[:tipo_valor].presence || 'bruto'
    aplicar_retencao = params[:aplicar_retencao] != false && params[:aplicar_retencao] != 'false'

    # Desconto já calculado pela proposta (não aplicar novamente)
    desconto_valor = total_desconto

    # Calcular retenções conforme Config Impostos:
    #   ATENÇÃO: optante_simples=true no DB significa NÃO optante (label invertido)
    #   Fornecedor NÃO optante simples (optante_simples=true): APLICAR retenção
    #   Fornecedor optante simples (optante_simples=false): ISENTO (0%)
    #   Não-simples + Federal:   Peças 5,85% | Serviços 9,45%
    #   Não-simples + Mun/Est:   Peças 1,20% | Serviços 4,80%
    is_federal = client.federal?
    total_retencao = 0.0

    order_services.each do |os|
      prop = find_approved_proposal(os)
      next unless prop
      # optante_simples=false = IS simples = ISENTO
      next unless prop.provider&.optante_simples  # true = NÃO simples = aplicar retenção

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

    valor_liquido = total_com_desconto
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

  rescue ActiveRecord::RecordNotFound => e
    respond_to do |format|
      format.html { redirect_to faturamento_index_path, alert: "Cliente ou OS não encontrado: #{e.message}" }
      format.json { render json: { error: "Cliente ou OS não encontrado: #{e.message}" }, status: :not_found }
    end
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.error "Fatura RecordNotUnique: #{e.message}"
    respond_to do |format|
      format.html { redirect_to faturamento_index_path, alert: "Número de fatura duplicado. Tente novamente." }
      format.json { render json: { error: "Número de fatura duplicado. Tente novamente." }, status: :unprocessable_entity }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html { redirect_to faturamento_index_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  rescue => e
    Rails.logger.error "Erro inesperado ao criar fatura: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
    respond_to do |format|
      format.html { redirect_to faturamento_index_path, alert: "Erro ao criar fatura: #{e.message}" }
      format.json { render json: { error: "Erro ao criar fatura: #{e.message}" }, status: :internal_server_error }
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

  def destroy
    authorize :faturamento, :destroy?
    @fatura = Fatura.includes(:fatura_itens).find(params[:id])

    unless %w[aberta cancelada].include?(@fatura.status)
      respond_to do |format|
        format.html { redirect_to faturamento_index_path, alert: "Fatura está #{@fatura.status}, não pode ser excluída. Apenas faturas abertas ou canceladas." }
        format.json { render json: { error: "Fatura está #{@fatura.status}, não pode ser excluída." }, status: :bad_request }
      end
      return
    end

    os_ids = @fatura.fatura_itens.where.not(order_service_id: nil).pluck(:order_service_id)

    ActiveRecord::Base.transaction do
      # Liberar as OS: voltar para status Autorizada e marcar como não faturada
      if os_ids.any?
        OrderService.where(id: os_ids).update_all(
          invoiced: false,
          invoiced_at: nil,
          order_service_status_id: OrderServiceStatus::AUTORIZADA_ID
        )
      end

      @fatura.destroy!
    end

    respond_to do |format|
      format.html { redirect_to faturamento_index_path, notice: "Fatura #{@fatura.numero} excluída. #{os_ids.size} OS liberadas para faturamento." }
      format.json { render json: { success: true, message: "Fatura excluída. #{os_ids.size} OS liberadas." } }
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_to faturamento_index_path, alert: "Erro ao excluir: #{e.message}" }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  def gerar_docx
    authorize :faturamento, :show?
    @fatura = apply_user_client_scope(Fatura.includes(
      fatura_itens: { order_service: [:vehicle, :cost_center, :sub_unit,
        { order_service_proposals: [:provider, :order_service_invoices] }] },
      client: [], cost_center: [], contract: []
    )).find(params[:id])

    service = Utils::OrderServices::GenerateInvoiceDocxService.new(@fatura, invoice_split: params[:split])
    docx_path = service.call

    send_file docx_path, filename: "fatura_#{@fatura.numero}.docx",
              type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
              disposition: 'attachment'
  rescue => e
    redirect_to faturamento_path(@fatura), alert: "Erro ao gerar documento: #{e.message}"
  end

  def gerar_pdf
    authorize :faturamento, :show?
    @fatura = apply_user_client_scope(Fatura.includes(
      fatura_itens: { order_service: [:vehicle, :cost_center, :sub_unit,
        { order_service_proposals: [:provider, :order_service_invoices] }] },
      client: [], cost_center: [], contract: []
    )).find(params[:id])

    service = Utils::OrderServices::GenerateInvoicePdfService.new(@fatura, invoice_split: params[:split])
    pdf_path = service.call

    send_file pdf_path, filename: "fatura_#{@fatura.numero}.pdf",
              type: 'application/pdf',
              disposition: 'attachment'
  rescue => e
    redirect_to faturamento_path(@fatura), alert: "Erro ao gerar PDF: #{e.message}"
  end

  def gerar_excel
    authorize :faturamento, :show?
    @fatura = apply_user_client_scope(Fatura.includes(:fatura_itens, :client, :cost_center, :contract)).find(params[:id])

    service = Utils::OrderServices::GenerateInvoiceExcelService.new(@fatura)
    excel_path = service.call

    send_file excel_path, filename: "fatura_#{@fatura.numero}.xls",
              type: 'application/vnd.ms-excel',
              disposition: 'attachment'
  rescue => e
    redirect_to faturamento_path(@fatura), alert: "Erro ao gerar Excel: #{e.message}"
  end

  # JSON: OS em aberto para um cliente
  def os_abertos_json
    authorize :faturamento, :abertos?
    client_id = params[:client_id]

    unless client_id.present?
      render json: { results: [] }
      return
    end

    # Somente OS em status Autorizada e não faturadas
    os_scope = OrderService.not_invoiced
                           .where(client_id: client_id)
                           .where(order_service_status_id: OrderServiceStatus::AUTORIZADA_ID)
                           .includes(:vehicle, :order_service_proposals, :cost_center, :sub_unit)

    # Filtro por período: busca OS que foram AUTORIZADAS naquele período (via audits)
    if params[:data_inicio].present? || params[:data_fim].present?
      os_scope = os_scope.approved_in_period(params[:data_inicio], params[:data_fim])
    end

    os_scope = os_scope.by_cost_center_id(params[:cost_center_id]) if params[:cost_center_id].present?

    if params[:sub_unit_id].present?
      os_scope = os_scope.joins(:vehicle).where(vehicles: { sub_unit_id: params[:sub_unit_id] })
    end

    # Filtro por empenho
    if params[:commitment_id].present?
      cid = params[:commitment_id].to_i
      os_scope = os_scope.where(
        'order_services.commitment_id = :cid OR order_services.commitment_parts_id = :cid OR order_services.commitment_services_id = :cid',
        cid: cid
      )
    end

    results = os_scope.order(:code).map do |os|
      proposal = find_approved_proposal(os)
      next nil unless proposal

      # NF numbers from proposal invoices
      invoices = proposal.order_service_invoices.to_a
      nf_pecas = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::PECAS_ID }.map(&:number).compact.join(', ')
      nf_servicos = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::SERVICOS_ID }.map(&:number).compact.join(', ')

      # Valores de NF por tipo (valores faturados = com desconto)
      nf_parts_value = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::PECAS_ID }.sum(&:value).to_f
      nf_services_value = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::SERVICOS_ID }.sum(&:value).to_f

      # Valores BRUTO por tipo (sem desconto) - calculados a partir dos itens da proposta
      items = OrderServiceProposal.items_for_totals(proposal)
      bruto_pecas = items.select { |i| i.service&.category_id == Category::SERVICOS_PECAS_ID }
                         .sum { |i| (i.total_value_without_discount.presence || (i.unity_value.to_d * i.quantity.to_d)).to_f }
      bruto_servicos = items.select { |i| i.service&.category_id == Category::SERVICOS_SERVICOS_ID }
                            .sum { |i| (i.total_value_without_discount.presence || (i.unity_value.to_d * i.quantity.to_d)).to_f }
      desc_pecas = items.select { |i| i.service&.category_id == Category::SERVICOS_PECAS_ID }
                        .sum { |i| i.discount.to_f }
      desc_servicos = items.select { |i| i.service&.category_id == Category::SERVICOS_SERVICOS_ID }
                           .sum { |i| i.discount.to_f }

      # Provider details
      prov = proposal.provider
      provider_name = prov&.fantasy_name.presence || prov&.social_name.presence || prov&.name
      provider_cnpj = prov&.cnpj
      provider_phone = prov&.phone.presence || prov&.cellphone.presence || prov&.get_first_phone_phone
      provider_email = prov&.email
      # ATENÇÃO: optante_simples=true no DB = NÃO optante (label "Não optante pelo SIMPLES")
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
        # Valores bruto (sem desconto) por tipo
        bruto_pecas: bruto_pecas,
        bruto_servicos: bruto_servicos,
        desc_pecas: desc_pecas,
        desc_servicos: desc_servicos,
        # Valores NF (com desconto) por tipo
        nf_pecas_value: nf_parts_value,
        nf_servicos_value: nf_services_value,
        # Totais da proposta
        total_bruto: proposal.total_value_without_discount.to_f,
        total_desconto: proposal.total_discount.to_f,
        total_com_desconto: proposal.total_value.to_f,
        nf_pecas: nf_pecas,
        nf_servicos: nf_servicos,
        contract_number: contract&.number,
        contract_name: contract&.name,
        commitment_number: commitment&.commitment_number,
        commitment_id: commitment&.id,
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

    # Empenhos do cliente para filtro
    client_commitments = Commitment.where(client_id: client_id, active: true).order(:commitment_number).map do |cm|
      { id: cm.id, number: cm.commitment_number, contract: cm.contract&.number }
    end

    render json: {
      results: results,
      cost_centers: client_cost_centers,
      client_discount: client_discount,
      client_sphere: client_sphere,
      contracts_info: contracts_info,
      commitment_numbers: commitment_numbers,
      commitments: client_commitments
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
    render json: { resumo: calcular_resumo, ultimas_faturas: apply_user_client_scope(Fatura).order(created_at: :desc).limit(5) }
  end

  def faturas_json_endpoint
    authorize :faturamento, :faturas?
    faturas = Fatura.includes(:client, :cost_center)
    faturas = apply_user_client_scope(faturas)
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

  def apply_user_client_scope(scope)
    if @current_user.client?
      scope.where(client_id: @current_user.id)
    elsif @current_user.manager? || @current_user.additional?
      scope.where(client_id: @current_user.client_id)
    else
      scope
    end
  end

  def find_approved_proposal(order_service)
    approved_statuses = OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES
    order_service.order_service_proposals
      .where(is_complement: [false, nil])
      .where(order_service_proposal_status_id: approved_statuses)
      .order(updated_at: :desc)
      .first
  end

  def calcular_resumo
    faturas = apply_user_client_scope(Fatura.all)

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
      nota_fiscal_numero_pecas: f.nota_fiscal_numero_pecas,
      nota_fiscal_serie_pecas: f.nota_fiscal_serie_pecas,
      nota_fiscal_numero_servicos: f.nota_fiscal_numero_servicos,
      nota_fiscal_serie_servicos: f.nota_fiscal_serie_servicos,
      numero_pecas: f.numero_pecas,
      numero_servicos: f.numero_servicos,
      nota_fiscal_pecas_file_url: (f.nota_fiscal_pecas_file.attached? ? Rails.application.routes.url_helpers.rails_blob_path(f.nota_fiscal_pecas_file, only_path: true) : nil),
      nota_fiscal_pecas_file_name: (f.nota_fiscal_pecas_file.attached? ? f.nota_fiscal_pecas_file.filename.to_s : nil),
      nota_fiscal_servicos_file_url: (f.nota_fiscal_servicos_file.attached? ? Rails.application.routes.url_helpers.rails_blob_path(f.nota_fiscal_servicos_file, only_path: true) : nil),
      nota_fiscal_servicos_file_name: (f.nota_fiscal_servicos_file.attached? ? f.nota_fiscal_servicos_file.filename.to_s : nil),
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
      :nota_fiscal_numero_pecas, :nota_fiscal_serie_pecas,
      :nota_fiscal_numero_servicos, :nota_fiscal_serie_servicos,
      :nota_fiscal_pecas_file, :nota_fiscal_servicos_file,
      :desconto, :valor_bruto
    )
  end

  def verify_access
    unless @current_user&.admin? || @current_user&.manager? || @current_user&.additional? || @current_user&.provider? || @current_user&.client?
      redirect_to root_path, alert: "Acesso negado."
    end
  end
end
