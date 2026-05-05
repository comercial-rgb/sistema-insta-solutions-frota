class CostCentersController < ApplicationController
  before_action :set_cost_center, only: [:show, :edit, :update, :destroy, :get_cost_center]

  def index
    authorize CostCenter

    if params[:cost_centers_grid].nil? || params[:cost_centers_grid].blank?
      @cost_centers = CostCentersGrid.new(:current_user => @current_user)
      @cost_centers_to_export = CostCentersGrid.new(:current_user => @current_user)
    else
      @cost_centers = CostCentersGrid.new(params[:cost_centers_grid].merge(current_user: @current_user))
      @cost_centers_to_export = CostCentersGrid.new(params[:cost_centers_grid].merge(current_user: @current_user))
    end

    if @current_user.manager? || @current_user.additional?
      client_id = @current_user.client_id
      cost_center_ids = @current_user.associated_cost_centers.map(&:id)
    end

    if @current_user.admin?
      @cost_centers.scope {|scope| scope.page(params[:page]) }
    elsif @current_user.client?
      @cost_centers.scope {|scope| scope.by_client_id(@current_user.id).page(params[:page]) }
      @cost_centers_to_export.scope {|scope| scope.by_client_id(@current_user.id) }
    elsif @current_user.manager?
      # Gerente vê apenas CCs do seu cliente
      @cost_centers.scope {|scope| scope.by_client_id(client_id).by_ids(cost_center_ids).page(params[:page]) }
      @cost_centers_to_export.scope {|scope| scope.by_client_id(client_id).by_ids(cost_center_ids) }
    elsif @current_user.additional?
      # Adicional vê apenas CCs do seu cliente
      @cost_centers.scope {|scope| scope.by_client_id(client_id).by_ids(cost_center_ids).page(params[:page]) }
      @cost_centers_to_export.scope {|scope| scope.by_client_id(client_id).by_ids(cost_center_ids) }
    end

    @bar_y_category_data = CostCenter.getting_data_to_show_in_dashboard(@cost_centers_to_export.assets.select{|item| !item.name.blank?})

    respond_to do |format|
      format.html
      format.csv do
        send_data @cost_centers_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: CostCenter.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def new
    authorize CostCenter
    @cost_center = CostCenter.new
    build_initial_relations
  end

  def edit
    authorize @cost_center
    build_initial_relations
  end

  def create
    authorize CostCenter
    @cost_center = CostCenter.new(cost_center_params)
    if @cost_center.save
      redirect_to edit_cost_center_path(@cost_center)
    else
      flash[:error] = @cost_center.errors.full_messages.join('<br>')
      build_initial_relations
      render :new
    end
  end

  def update
    authorize @cost_center
    @cost_center.update(cost_center_params)
    if @cost_center.valid?
      flash[:success] = t('flash.update')
      redirect_to cost_centers_path
    else
      flash[:error] = @cost_center.errors.full_messages.join('<br>')
      build_initial_relations
      render :edit
    end
  end

  def show
    authorize @cost_center

    @commitments = @cost_center.commitments.order(created_at: :desc).page(params[:commitments_page]).per(20)
    @vehicles = @cost_center.vehicles.order(:board).page(params[:vehicles_page]).per(15)
  end

  def destroy
    authorize @cost_center
    if @cost_center.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @cost_center.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def build_initial_relations
    if @cost_center.sub_units.select{ |item| item[:id].nil? }.length == 0
     @cost_center.sub_units.build
    end
    # @cost_center.build_relation if @cost_center.relation.nil?
  end

  def get_cost_center
    data = {
      result: @cost_center
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def by_client_id
    authorize CostCenter, :index?

    client_id = if @current_user.admin?
                  params[:client_id]
                elsif @current_user.client?
                  @current_user.id
                else
                  @current_user.client_id
                end

    # Usa unscoped para evitar efeitos colaterais de default_scope no endpoint AJAX.
    relation = CostCenter.unscoped.where(client_id: client_id)

    if @current_user.manager? || @current_user.additional?
      allowed_cost_center_ids = @current_user.associated_cost_centers.pluck(:id)
      # Se o vínculo N:N não existir para o usuário, mantém os CCs do cliente.
      relation = relation.where(id: allowed_cost_center_ids) if allowed_cost_center_ids.present?
    end

    if params[:only_order_services].present? && params[:only_order_services].to_i == 1
      relation = relation.joins(:order_services).distinct
    end

    result_payload = relation.reorder('cost_centers.name ASC')
                             .pluck(:id, :name)
                             .map { |id, name| { id: id, name: name } }

    Rails.logger.info("[CostCenters#by_client_id] user_id=#{@current_user.id} client_id=#{client_id} count=#{result_payload.size}")
    render json: { result: result_payload }, status: :ok
  rescue => e
    Rails.logger.error("[CostCenters#by_client_id] ERROR user_id=#{@current_user&.id} client_id=#{params[:client_id]} #{e.class}: #{e.message}")
    render json: { result: [] }, status: :ok
  end

  def sub_units_by_cost_center_id
    authorize CostCenter, :index?

    if @current_user.manager? || @current_user.additional?
      cost_center_ids = @current_user.associated_cost_centers.pluck(:id)
      sub_unit_ids = @current_user.associated_sub_units.pluck(:id)
      relation = SubUnit.by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids).by_cost_center_ids([params[:cost_center_id]])
    else
      relation = SubUnit.by_cost_center_ids([params[:cost_center_id]])
    end

    result_payload = relation.order(:name).pluck(:id, :name).map { |id, name| { id: id, name: name } }
    render json: { result: result_payload }, status: :ok
  rescue => e
    Rails.logger.error("[CostCenters#sub_units_by_cost_center_id] ERROR user_id=#{@current_user&.id} cost_center_id=#{params[:cost_center_id]} #{e.class}: #{e.message}")
    render json: { result: [] }, status: :ok
  end

  def sub_units_by_client_id
    authorize CostCenter, :index?
    client_id = @current_user.admin? ? params[:client_id]
              : @current_user.client? ? @current_user.id
              : @current_user.client_id
    cost_centers = CostCenter.unscoped.where(client_id: client_id)
    sub_units = SubUnit.where(cost_center_id: cost_centers.pluck(:id)).order(:name)
    result_payload = sub_units.pluck(:id, :name).map { |id, name| { id: id, name: name } }
    render json: { result: result_payload }, status: :ok
  rescue => e
    Rails.logger.error("[CostCenters#sub_units_by_client_id] ERROR user_id=#{@current_user&.id} client_id=#{params[:client_id]} #{e.class}: #{e.message}")
    render json: { result: [] }, status: :ok
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_cost_center
    scope = CostCenter.all
    if @current_user.client?
      scope = scope.where(client_id: @current_user.id)
    elsif @current_user.manager? || @current_user.additional?
      scope = scope.where(client_id: @current_user.client_id)
    end
    @cost_center = scope.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white.
  def cost_center_params
    params.require(:cost_center).permit(:id,
    :client_id,
    :name,
    :contract_number,
    :commitment_number,
    :initial_consumed_balance,
    :description,
    :budget_value,
    :budget_type_id,
    :contract_initial_date,
    :has_sub_units,
    :already_consumed_value,
    :invoice_name,
    :invoice_cnpj,
    :invoice_address,
    :invoice_state_id,
    :invoice_fantasy_name,
    :skip_validations,
    sub_units_attributes: [
      :id, :cost_center_id, :name, :contract_number,
      :commitment_number, :initial_consumed_balance,
      :budget_value, :budget_type_id, :contract_initial_date
    ],
    contract_ids: []
    )
  end
end
