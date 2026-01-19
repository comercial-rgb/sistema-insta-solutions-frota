class ContractsController < ApplicationController
  before_action :set_contract, only: [:show, :edit, :update, :destroy, :get_contract]

  def show
    authorize @contract
    
    # Busca empenhos vinculados ao contrato
    @commitments = @contract.commitments.includes(:cost_center, :sub_unit, :category).order(created_at: :desc)
    
    # Busca OSs aprovadas/autorizadas vinculadas ao contrato através dos empenhos
    commitment_ids = @commitments.pluck(:id)
    @approved_order_services = OrderService
      .where(order_service_status_id: OrderServiceStatus::REQUIRED_ORDER_SERVICE_STATUSES)
      .where("commitment_id IN (?) OR commitment_parts_id IN (?) OR commitment_services_id IN (?)", 
             commitment_ids, commitment_ids, commitment_ids)
      .includes(:vehicle, :cost_center, :commitment, :order_service_status)
      .order(created_at: :desc)
    
    # Calcula valores
    @total_value = @contract.get_total_value
    @used_value = @contract.get_used_value
    @available_value = @contract.get_disponible_value
  end

  def index
    authorize Contract

    if params[:contracts_grid].nil? || params[:contracts_grid].blank?
      @contracts = ContractsGrid.new(:current_user => @current_user)
      @contracts_to_export = ContractsGrid.new(:current_user => @current_user)
    else
      @contracts = ContractsGrid.new(params[:contracts_grid].merge(current_user: @current_user))
      @contracts_to_export = ContractsGrid.new(params[:contracts_grid].merge(current_user: @current_user))
    end

    if @current_user.admin?
      @contracts.scope {|scope| scope.page(params[:page]) }
    elsif @current_user.manager? || @current_user.additional?
      @contracts.scope {|scope| scope.where(client_id: @current_user.client_id).page(params[:page]) }
      @contracts_to_export.scope {|scope| scope.where(client_id: @current_user.client_id) }
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data @contracts_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: Contract.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def new
    authorize Contract
    if Rails.env.development?
      generate_data_contract
    else
      @contract = Contract.new
    end
    build_initial_relations
  end

  def edit
    authorize @contract
    build_initial_relations
  end


  def generate_data_contract
    @contract = FactoryBot.build(:contract)
  end

  def create
    authorize Contract
    @contract = Contract.new(contract_params)
    if @contract.save
      flash[:success] = t('flash.create')
      redirect_to contracts_path
    else
      flash[:error] = @contract.errors.full_messages.join('<br>')
      build_initial_relations
      render :new
    end
  end

  def update
    authorize @contract
    @contract.update(contract_params)
    if @contract.valid?
      flash[:success] = t('flash.update')
      redirect_to contracts_path
    else
      flash[:error] = @contract.errors.full_messages.join('<br>')
      build_initial_relations
      render :edit
    end
  end

  def destroy
    authorize @contract
    @contract.cost_centers.clear
    if @contract.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @contract.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def build_initial_relations
    if @contract.addendum_contracts.select{ |item| item[:id].nil? }.length == 0
     @contract.addendum_contracts.build
    end
    # @contract.build_relation if @contract.relation.nil?
  end

  def get_contract
    data = {
      result: @contract
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def by_client_id
    client_id = params[:client_id]
    contracts = Contract.where(client_id: client_id, active: true).order(:name)
    data = {
      result: contracts.map { |c| { id: c.id, name: c.get_formatted_name_with_disponible_value } }
    }
    respond_to do |format|
      format.json { render json: data, status: 200 }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_contract
    @contract = Contract.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white.
  def contract_params
    params.require(:contract).permit(:id,
    :client_id,
    :name,
    :number,
    :total_value,
    :active,
    :initial_date,
    :final_date,
    addendum_contracts_attributes: [
      :id, :contract_id, :name, :number, :total_value, :active
    ]
    )
  end
end
