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
    @clients = User.client.order(:name)
    @cost_centers = CostCenter.order(:name)

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
    @fatura = Fatura.new(fatura_params)
    @fatura.numero = Fatura.gerar_numero
    @fatura.data_emissao ||= Date.current
    @fatura.calcular_retencoes!

    if @fatura.save
      redirect_to faturamento_path(@fatura), notice: "Fatura #{@fatura.numero} criada com sucesso!"
    else
      redirect_to faturamento_index_path, alert: @fatura.errors.full_messages.join(', ')
    end
  end

  def update
    authorize :faturamento, :update?
    @fatura = Fatura.find(params[:id])

    if @fatura.update(fatura_update_params)
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
      cliente: f.client&.name || '-',
      client_id: f.client_id,
      centro_custo: f.cost_center&.name || '-',
      cost_center_id: f.cost_center_id,
      data_emissao: f.data_emissao,
      data_emissao_fmt: f.data_emissao&.strftime('%d/%m/%Y'),
      data_envio_empresa: f.data_envio_empresa,
      data_envio_fmt: f.data_envio_empresa&.strftime('%d/%m/%Y'),
      data_vencimento: f.data_vencimento,
      data_vencimento_fmt: f.data_vencimento&.strftime('%d/%m/%Y'),
      status: f.status,
      valor_bruto: f.valor_bruto.to_f,
      valor_liquido: f.valor_liquido.to_f,
      total_retencoes: f.total_retencoes.to_f,
      taxa_administracao: f.taxa_administracao.to_f,
      nota_fiscal_numero: f.nota_fiscal_numero,
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
      nota_fiscal_serie: f.nota_fiscal_serie,
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
      :valor_bruto, :ir_percentual, :pis_percentual, :cofins_percentual, :csll_percentual,
      :taxa_administracao, :nota_fiscal_numero, :nota_fiscal_serie,
      :observacoes
    )
  end

  def fatura_update_params
    params.require(:fatura).permit(
      :status, :data_envio_empresa, :data_recebimento, :data_vencimento,
      :admin_observacoes, :nota_fiscal_numero, :nota_fiscal_serie
    )
  end

  def verify_access
    unless @current_user&.admin? || @current_user&.manager? || @current_user&.additional? || @current_user&.provider? || @current_user&.client?
      redirect_to root_path, alert: "Acesso negado."
    end
  end
end
