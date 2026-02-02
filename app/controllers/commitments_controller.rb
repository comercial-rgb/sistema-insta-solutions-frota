class CommitmentsController < ApplicationController
  before_action :set_commitment, only: [:show, :edit, :update, :destroy, :get_commitment, :save_cancel_commitment, :inactivate]

  def show
    authorize @commitment

    base_order_services_relation = if @commitment.category_id == Category::SERVICOS_PECAS_ID
      @commitment.order_services_parts
    elsif @commitment.category_id == Category::SERVICOS_SERVICOS_ID
      @commitment.order_services_services
    else
      @commitment.order_services
    end
    
    # Busca as OSs aprovadas/autorizadas/pagas vinculadas ao empenho
    @approved_order_services = base_order_services_relation
      .where(order_service_status_id: OrderServiceStatus::REQUIRED_ORDER_SERVICE_STATUSES)
      .includes(:vehicle, :cost_center, :order_service_status)
      .order(created_at: :desc)
      .page(params[:approved_order_services_page]).per(20)
    
    # Calcula valores
    @total_consumed = Commitment.get_total_already_consumed_value(@commitment)
    addendum_value = @commitment.addendum_commitments.where(active: true).sum(:total_value).to_f
    @remaining_value = @commitment.commitment_value.to_f + addendum_value - @total_consumed - @commitment.canceled_value.to_f

    related = Commitment.where(
      client_id: @commitment.client_id,
      contract_id: @commitment.contract_id,
      commitment_number: @commitment.commitment_number
    )
    related = related.where(sub_unit_id: @commitment.sub_unit_id) if @commitment.sub_unit_id.present?
    related = related.where(active: true)

    parts_commitment = related.find { |c| c.category_id == Category::SERVICOS_PECAS_ID }
    services_commitment = related.find { |c| c.category_id == Category::SERVICOS_SERVICOS_ID }

    @commitment_breakdown = {
      parts: parts_commitment,
      services: services_commitment
    }
  end

  def index
    authorize Commitment

    if params[:commitments_grid].nil? || params[:commitments_grid].blank?
      @commitments = CommitmentsGrid.new(:current_user => @current_user)
      @commitments_to_export = CommitmentsGrid.new(:current_user => @current_user)
    else
      @commitments = CommitmentsGrid.new(params[:commitments_grid].merge(current_user: @current_user))
      @commitments_to_export = CommitmentsGrid.new(params[:commitments_grid].merge(current_user: @current_user))
    end
    @commitments_to_filter = CommitmentsGrid.new(:current_user => @current_user)

    if @current_user.manager? || @current_user.additional?
      client_id = current_user.client_id
      cost_center_ids = current_user.associated_cost_centers.map(&:id)
      sub_unit_ids = current_user.associated_sub_units.map(&:id)
    end

    if @current_user.admin?
      @commitments.scope {|scope| scope.page(params[:page]) }
    elsif @current_user.manager? || @current_user.additional?
      client_id = @current_user.client_id
      cost_center_ids = @current_user.associated_cost_centers.map(&:id)
      sub_unit_ids = @current_user.associated_sub_units.map(&:id)
      # Filtrar apenas empenhos do cliente e dos CCs/SUs autorizados
      @commitments.scope {|scope| scope.by_client_id(client_id).by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids).page(params[:page]) }
      @commitments_to_export.scope {|scope| scope.by_client_id(client_id).by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids) }
      @commitments_to_filter.scope {|scope| scope.by_client_id(client_id).by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids) }
    end

    # Coleta IDs de centros de custo da nova tabela de relacionamento e do campo legado
    cost_center_ids = @commitments_to_filter.assets.flat_map do |item|
      if item.cost_centers.any?
        item.cost_centers.pluck(:id)
      elsif item.cost_center_id.present?
        [item.cost_center_id]
      else
        []
      end
    end.uniq
    cost_centers = CostCenter.where(id: cost_center_ids).order(:name).map {|c| [c.name, c.id] }

    contract_ids = @commitments_to_filter.assets.map{|item| item.contract_id}.flatten
    contracts = Contract.where(id: [contract_ids]).order(:name).map {|c| [c.name, c.id] }

    sub_unit_ids = @commitments_to_filter.assets.map{|item| item.sub_unit_id}.flatten
    sub_units = SubUnit.where(id: [sub_unit_ids]).order(:name).map {|c| [c.name, c.id] }

    @commitments.cost_centers = cost_centers
    @commitments.contracts = contracts
    @commitments.sub_units = sub_units

    @commitments_to_export.cost_centers = cost_centers
    @commitments_to_export.contracts = contracts
    @commitments_to_export.sub_units = sub_units

    respond_to do |format|
      format.html
      format.csv do
        send_data @commitments_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: Commitment.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def new
    authorize Commitment
    @commitment = Commitment.new
    build_initial_relations
  end

  def edit
    authorize @commitment
    build_initial_relations
  end

  def create
    authorize Commitment
    @commitment = Commitment.new(commitment_params)
    if @commitment.save
      flash[:success] = t('flash.create')
      redirect_to commitments_path
    else
      flash[:error] = @commitment.errors.full_messages.join('<br>')
      build_initial_relations
      render :new
    end
  end

  def update
    # LOG MUITO NO TOPO - ANTES DE QUALQUER COISA
    Rails.logger.info "=" * 80
    Rails.logger.info "🔍 [COMMITMENT UPDATE INICIADO] ID: #{params[:id]}, Todos params: #{params.inspect}"
    Rails.logger.info "=" * 80
    
    authorize @commitment
    
    # Log para debug
    Rails.logger.info "🔍 [COMMITMENT UPDATE] Params recebidos: #{commitment_params.inspect}"
    Rails.logger.info "🔍 [COMMITMENT UPDATE] Valor antes: #{@commitment.commitment_value}"
    
    # Verificar se admin está editando valor e se ficará negativo
    if @current_user.admin? && commitment_params[:commitment_value].present?
      new_value = commitment_params[:commitment_value].to_s.gsub(/[^\d,]/, '').gsub(',', '.').to_f
      total_consumed = Commitment.get_total_already_consumed_value(@commitment)
      
      Rails.logger.info "🔍 [COMMITMENT UPDATE] Novo valor convertido: #{new_value}, Consumido: #{total_consumed}"
      
      if new_value < total_consumed
        remaining = new_value - total_consumed
        flash.now[:warning] = "⚠️ ATENÇÃO: O valor do empenho (#{CustomHelper.to_currency(new_value)}) é menor que o já consumido (#{CustomHelper.to_currency(total_consumed)}). O saldo disponível ficará NEGATIVO: #{CustomHelper.to_currency(remaining)}."
      end
    end
    
    result = @commitment.update(commitment_params)
    Rails.logger.info "🔍 [COMMITMENT UPDATE] Valor depois: #{@commitment.commitment_value}, Update result: #{result}"
    
    if @commitment.valid?
      flash[:success] = t('flash.update')
      redirect_to commitments_path
    else
      flash[:error] = @commitment.errors.full_messages.join('<br>')
      build_initial_relations
      render :edit
    end
  end

  def save_cancel_commitment
    authorize @commitment
    @commitment.skip_validations = true
    @commitment.update(commitment_params)
    if @commitment.valid?
      flash[:success] = t('flash.update')
      @commitment.update(canceled_value: @commitment.cancel_commitments.sum(:value))
      redirect_to commitments_path
    else
      flash[:error] = @commitment.errors.full_messages.join('<br>')
      build_initial_relations
      render :edit
    end
  end

  def inactivate
    authorize @commitment, :inactivate?
    if @commitment.update(active: false)
      flash[:success] = t('model.inactivate', default: 'Inativado')
    else
      flash[:error] = @commitment.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: commitments_path)
  end

  def destroy
    authorize @commitment
    if @commitment.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @commitment.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def build_initial_relations
    if @commitment.cancel_commitments.select{ |item| item[:id].nil? }.length == 0
     @commitment.cancel_commitments.build
    end
    # @commitment.build_relation if @commitment.relation.nil?
  end

  def get_commitment
    data = {
      result: @commitment
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_commitment
    @commitment = Commitment.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white.
  def commitment_params
    params.require(:commitment).permit(:id,
    :client_id,
    :cost_center_id,
    :sub_unit_id,
    :contract_id,
    :commitment_number,
    :commitment_value,
    :category_id,
    :active,
    :skip_validations,
    cost_center_ids: [],
    cancel_commitments_attributes: [:id, :commitment_id, :value, :number, :date]
    )
  end
end
