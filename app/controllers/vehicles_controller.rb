class VehiclesController < ApplicationController
  before_action :set_vehicle, only: [:show, :edit, :update, :destroy, :get_vehicle, :order_services]

  def index
    authorize Vehicle

    if @current_user.manager? || @current_user.additional?
      client_id = @current_user.client_id
      cost_center_ids = @current_user.associated_cost_centers.map(&:id)
      sub_unit_ids = @current_user.associated_sub_units.map(&:id)
    end

    if params[:vehicles_grid].nil? || params[:vehicles_grid].blank?
      @vehicles = VehiclesGrid.new(:current_user => @current_user)
      @vehicles_to_export = VehiclesGrid.new(:current_user => @current_user)
    else
      @vehicles = VehiclesGrid.new(params[:vehicles_grid].merge(current_user: @current_user))
      @vehicles_to_export = VehiclesGrid.new(params[:vehicles_grid].merge(current_user: @current_user))
    end

    if @current_user.admin?
      @vehicles.scope {|scope| scope.page(params[:page]) }
    elsif @current_user.manager?
      @vehicles.scope {|scope| scope.by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids).page(params[:page]) }
      @vehicles_to_export.scope {|scope| scope.by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids) }
    elsif @current_user.additional?
      @vehicles.scope {|scope| scope.by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids).page(params[:page]) }
      @vehicles_to_export.scope {|scope| scope.by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids) }
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data @vehicles_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: Vehicle.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
      format.pdf do
        pdf = Utils::DatagridPdfExporter.new(@vehicles_to_export, title: Vehicle.model_name.human(count: 2)).call
        send_data pdf,
          type: 'application/pdf',
          disposition: 'inline',
          filename: Vehicle.model_name.human(count: 2)+" - #{Time.now.to_s}.pdf"
      end
    end
  end

  def new
    authorize Vehicle
    @vehicle = Vehicle.new
    build_initial_relations
  end

  def edit
    authorize @vehicle
    build_initial_relations
  end

  def show
    authorize @vehicle, :show?
    build_initial_relations
    render :edit
  end

  def create
    authorize Vehicle
    @vehicle = Vehicle.new(vehicle_params)
    if @vehicle.save
      flash[:success] = t('flash.create')
      redirect_to vehicles_path
    else
      flash[:error] = @vehicle.errors.full_messages.join('<br>')
      build_initial_relations
      render :new
    end
  end

  def update
    authorize @vehicle
    
    Rails.logger.info "🔍 [VEHICLE UPDATE] ID: #{@vehicle.id}, Params: #{vehicle_params.inspect}"
    Rails.logger.info "🔍 [VEHICLE UPDATE] cost_center_id antes: #{@vehicle.cost_center_id}"
    
    begin
      update_result = @vehicle.update(vehicle_params)
      
      Rails.logger.info "🔍 [VEHICLE UPDATE] Update result: #{update_result}"
      Rails.logger.info "🔍 [VEHICLE UPDATE] cost_center_id depois: #{@vehicle.cost_center_id}"
      
      if @vehicle.valid?
        flash[:success] = t('flash.update')
        redirect_to vehicles_path
      else
        Rails.logger.error "❌ [VEHICLE UPDATE] Erros de validação: #{@vehicle.errors.full_messages.join(', ')}"
        flash[:error] = @vehicle.errors.full_messages.join('<br>')
        build_initial_relations
        render :edit
      end
    rescue => e
      Rails.logger.error "❌ [VEHICLE UPDATE] Exceção: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      flash[:error] = "Erro ao atualizar veículo: #{e.message}"
      build_initial_relations
      render :edit
    end
  end

  def destroy
    authorize @vehicle
    if @vehicle.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @vehicle.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def build_initial_relations
    # if @vehicle.relations.select{ |item| item[:id].nil? }.length == 0
    #  @vehicle.relations.build
    # end
    # @vehicle.build_relation if @vehicle.relation.nil?
    if defined?(@vehicle) && @vehicle.present? && @vehicle.persisted?
      @order_services_for_vehicle = @vehicle.order_services
        .includes(:order_service_status, :order_service_type)
        .order(updated_at: :desc)
        .page(params[:os_page])
        .per(10)
      
      # Carregar itens em garantia do veículo
      @warranty_items_vehicle = get_warranty_items_for_vehicle(@vehicle)
    end
  end
  
  # Busca itens em garantia para um veículo específico
  def get_warranty_items_for_vehicle(vehicle)
    return [] unless vehicle&.persisted?
    
    today = Time.zone.today

    # ✅ Regra solicitada: contar garantia apenas quando a OS estiver AUTORIZADA (ou posterior)
    valid_order_service_statuses = [
      OrderServiceStatus::AUTORIZADA_ID,
      OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID,
      OrderServiceStatus::PAGA_ID
    ]

    # Propostas autorizadas ou posteriores (garantia já iniciou)
    valid_proposal_statuses = [
      OrderServiceProposalStatus::AUTORIZADA_ID,
      OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
      OrderServiceProposalStatus::PAGA_ID
    ]

    items = OrderServiceProposalItem
      .joins(order_service_proposal: :order_service)
      .includes(:service, order_service_proposal: [:provider, :order_service])
      .where(order_services: { vehicle_id: vehicle.id, order_service_status_id: valid_order_service_statuses })
      .where(order_service_proposals: { order_service_proposal_status_id: valid_proposal_statuses })
      .where.not(order_service_proposal_items: { warranty_period: [nil, 0] })

    warranty_items = items.map do |item|
      proposal = item.order_service_proposal
      service = item.service

      start_date = item.warranty_start_date || proposal.updated_at.to_date
      expires_at = start_date + item.warranty_period.to_i.days
      remaining_days = (expires_at - today).to_i
      next unless remaining_days.positive?

      unity_value = item.unity_value.to_d
      quantity = item.quantity.to_d
      total_value = item.total_value.presence || (unity_value * quantity)

      is_part = service&.category_id == Category::SERVICOS_PECAS_ID

      {
        name: item.service_name.presence || service&.name,
        brand: item.brand.presence || service&.brand,
        code: service&.code,
        value: total_value.to_f,
        warranty_period: item.warranty_period,
        expires_at: expires_at,
        remaining_days: remaining_days,
        provider_name: proposal.provider&.get_name,
        order_service_id: proposal.order_service_id,
        order_service_code: proposal.order_service&.code,
        is_part: is_part
      }
    end.compact

    warranty_items.sort_by { |row| row[:remaining_days] }.first(15)
  end

  def get_vehicle
    data = {
      result: @vehicle
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def order_services
    authorize @vehicle

    order_services_scope = @vehicle.order_services
      .includes(:order_service_status, :provider_service_type, :order_service_type, vehicle: [:cost_center, :sub_unit])
      .order(updated_at: :desc)

    if @current_user.manager? || @current_user.additional?
      allowed_cost_center_ids = @current_user.associated_cost_centers.map(&:id)
      allowed_sub_unit_ids = @current_user.associated_sub_units.map(&:id)

      unless allowed_cost_center_ids.include?(@vehicle.cost_center_id) || allowed_sub_unit_ids.include?(@vehicle.sub_unit_id)
        head :forbidden and return
      end

      order_services_scope = order_services_scope.by_cost_center_or_sub_unit_ids(allowed_cost_center_ids, allowed_sub_unit_ids)
    end

    @order_services_for_vehicle = order_services_scope
      .page(params[:os_modal_page])
      .per(15)

    render partial: 'vehicles/order_services_modal_table', locals: { order_services: @order_services_for_vehicle }
  end

  def vehicles_by_cost_center_id
    data = {
      result: Vehicle.by_cost_center_ids([params[:cost_center_id]])
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def vehicles_by_client_id
    data = {
      result: Vehicle.by_active(params[:active]).by_client_ids([params[:client_id]])
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def commitments_by_vehicle_id
    vehicle = Vehicle.find(params[:vehicle_id])
    cost_center_id = vehicle.cost_center_id
    sub_unit_id = vehicle.sub_unit_id
    result = Commitment.getting_data_by_user(@current_user, params[:client_id], cost_center_id, sub_unit_id)
    client_needs_km = vehicle.client.needs_km
    last_km = 0
    if client_needs_km
      last_km = vehicle.getting_last_km
    end
    data = {
      result: result,
      client_needs_km: client_needs_km,
      last_km: last_km
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def commitment_types_by_vehicle_id
    vehicle = Vehicle.find(params[:vehicle_id])
    cost_center_id = vehicle.cost_center_id
    sub_unit_id = vehicle.sub_unit_id
    client_id = params[:client_id]
    
    # Obter empenhos disponíveis para este veículo
    commitments = Commitment.getting_data_by_user(@current_user, client_id, cost_center_id, sub_unit_id)
    
    # Identificar tipos de empenhos disponíveis
    has_global = commitments.any? { |c| c.category_id.nil? }
    has_parts = commitments.any? { |c| c.category_id == Category::SERVICOS_PECAS_ID }
    has_services = commitments.any? { |c| c.category_id == Category::SERVICOS_SERVICOS_ID }
    
    data = {
      has_global: has_global,
      has_parts: has_parts,
      has_services: has_services,
      commitments: commitments.map { |c| { id: c.id, name: c.get_formatted_name_with_pendent_value, category_id: c.category_id } }
    }
    
    respond_to do |format|
      format.json { render json: data, status: 200 }
    end
  end

  def last_order_service_by_vehicle_id
    last_order_service = OrderService.includes(:order_service_status).where(vehicle_id: params[:vehicle_id]).last
    data = {
      result: last_order_service
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def getting_vehicle_by_plate_integration
    authorize Vehicle
    result = Utils::ApiPlacas::ConsultPlateService.new(params[:plate]).call
    if result
      tipo_veiculo = result["extra"] ? result["extra"]["tipo_veiculo"] : ""
      vehicle_type = VehicleType.find_or_create_by(name: tipo_veiculo)

      combustivel = result["extra"] ? result["extra"]["combustivel"] : ""
      fuel_type = FuelType.find_or_create_by(name: combustivel)

      state_uf = result["uf"]
      state = State.find_by(acronym: state_uf) || nil

      city_name = result["municipio"]
      city = city_name.present? ? City.where('LOWER(name) = ?', city_name.to_s.downcase).first : nil

      engine_displacement = result["extra"] ? result["extra"]["cilindradas"] : ""
      gearbox_type = result["extra"] ? result["extra"]["caixa_cambio"] : ""
      fipe_code = (result["fipe"] && result["fipe"]["dados"] && result["fipe"]["dados"].length > 0) ? result["fipe"]["dados"][0]["codigo_fipe"] : ""
      model_text = (result["fipe"] && result["fipe"]["dados"] && result["fipe"]["dados"].length > 0) ? result["fipe"]["dados"][0]["texto_modelo"] : ""
      value_text = (result["fipe"] && result["fipe"]["dados"] && result["fipe"]["dados"].length > 0) ? result["fipe"]["dados"][0]["texto_valor"] : ""

      render json: {
        success: true,
        data: {
          plate: result["placa"],
          renavam: result["extra"] ? result["extra"]["renavam"] : "",
          brand: result["marca"],
          color: result["cor"],
          model: result["modelo"],
          year_manufacture: result["extra"] ? result["extra"]["ano_fabricacao"] : "",
          year_model: result["extra"] ? result["extra"]["ano_modelo"] : "",
          vehicle_type: vehicle_type,
          fuel_type: fuel_type,
          state: state,
          city: city,
          chassi: result["extra"] ? result["extra"]["chassi"] : result["chassi"],
          situation: result["situacao"],
          engine_displacement: engine_displacement,
          gearbox_type: gearbox_type,
          fipe_code: fipe_code,
          model_text: model_text,
          value_text: value_text,
        }
      }
    else
      render json: { success: false, error: 'Placa não encontrada ou inválida.' }, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_vehicle
    @vehicle = Vehicle.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white.
  def vehicle_params
    params.require(:vehicle).permit(:id,
    :client_id,
    :cost_center_id,
    :sub_unit_id,
    :board,
    :brand,
    :model,
    :year,
    :color,
    :renavam,
    :chassi,
    :market_value,
    :acquisition_date,
    :vehicle_type_id,
    :category_id,
    :state_id,
    :city_id,
    :fuel_type_id,
    :active,
    :model_year,
    :current_owner_name,
    :old_owner_name,
    :current_owner_document,
    :engine_displacement,
    :gearbox_type,
    :fipe_code,
    :model_text,
    :value_text
    )
  end
end
