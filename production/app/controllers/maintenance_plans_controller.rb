class MaintenancePlansController < ApplicationController
  before_action :set_maintenance_plan, only: [:show, :edit, :update, :destroy, :add_vehicles, :remove_vehicle]

  def index
    authorize MaintenancePlan

    if params[:maintenance_plans_grid].nil? || params[:maintenance_plans_grid].blank?
      @maintenance_plans = MaintenancePlansGrid.new(current_user: @current_user)
    else
      @maintenance_plans = MaintenancePlansGrid.new(params[:maintenance_plans_grid].merge(current_user: @current_user))
    end

    if @current_user.admin?
      @maintenance_plans.scope { |scope| scope.page(params[:page]) }
    else
      client_id = @current_user.client_id.present? ? @current_user.client_id : @current_user.id
      @maintenance_plans.scope { |scope| scope.by_client(client_id).page(params[:page]) }
    end

    respond_to do |format|
      format.html
    end
  end

  def new
    authorize MaintenancePlan
    @maintenance_plan = MaintenancePlan.new
    @maintenance_plan.maintenance_plan_items.build
  end

  def edit
    authorize @maintenance_plan
    @maintenance_plan.maintenance_plan_items.build if @maintenance_plan.maintenance_plan_items.empty?
  end

  def show
    authorize @maintenance_plan, :show?
    render :edit
  end

  def create
    authorize MaintenancePlan
    @maintenance_plan = MaintenancePlan.new(maintenance_plan_params)

    if @current_user.admin? && params[:maintenance_plan][:client_id].present?
      @maintenance_plan.client_id = params[:maintenance_plan][:client_id]
    elsif !@current_user.admin?
      @maintenance_plan.client_id = @current_user.client_id.present? ? @current_user.client_id : @current_user.id
    end

    if @maintenance_plan.save
      flash[:success] = t('flash.create')
      redirect_to edit_maintenance_plan_path(@maintenance_plan)
    else
      flash[:error] = @maintenance_plan.errors.full_messages.join('<br>')
      render :new
    end
  end

  def update
    authorize @maintenance_plan

    if @maintenance_plan.update(maintenance_plan_params)
      flash[:success] = t('flash.update')
      redirect_to edit_maintenance_plan_path(@maintenance_plan)
    else
      flash[:error] = @maintenance_plan.errors.full_messages.join('<br>')
      render :edit
    end
  end

  def destroy
    authorize @maintenance_plan
    @maintenance_plan.destroy
    flash[:success] = t('flash.destroy')
    redirect_to maintenance_plans_path
  end

  def add_vehicles
    authorize @maintenance_plan, :update?
    vehicle_ids = params[:vehicle_ids] || []
    vehicle_ids.each do |vid|
      @maintenance_plan.maintenance_plan_vehicles.find_or_create_by(vehicle_id: vid)
    end
    flash[:success] = "Veículos vinculados com sucesso."
    redirect_to edit_maintenance_plan_path(@maintenance_plan)
  end

  def remove_vehicle
    authorize @maintenance_plan, :update?
    @maintenance_plan.maintenance_plan_vehicles.where(vehicle_id: params[:vehicle_id]).destroy_all
    flash[:success] = "Veículo removido do plano."
    redirect_to edit_maintenance_plan_path(@maintenance_plan)
  end

  # JSON: veículos disponíveis para vincular
  def available_vehicles
    authorize MaintenancePlan, :index?
    scope = MaintenancePlan.all
    if @current_user.client?
      scope = scope.where(client_id: @current_user.id)
    elsif @current_user.manager? || @current_user.additional?
      scope = scope.where(client_id: @current_user.client_id)
    end
    plan = scope.find(params[:id])
    client_id = plan.client_id

    if client_id.present?
      vehicles = Vehicle.where(client_id: client_id).where.not(id: plan.vehicle_ids).order(:board)
    else
      vehicles = Vehicle.where.not(id: plan.vehicle_ids).order(:board)
    end

    render json: vehicles.map { |v| { id: v.id, text: "#{v.board} - #{v.model}" } }
  end

  private

  def set_maintenance_plan
    scope = MaintenancePlan.all
    if @current_user.client?
      scope = scope.where(client_id: @current_user.id)
    elsif @current_user.manager? || @current_user.additional?
      scope = scope.where(client_id: @current_user.client_id)
    end
    @maintenance_plan = scope.find(params[:id])
  end

  def maintenance_plan_params
    params.require(:maintenance_plan).permit(
      :name, :description, :active, :client_id,
      maintenance_plan_items_attributes: [
        :id, :name, :plan_type, :km_interval, :days_interval,
        :km_alert_threshold, :days_alert_threshold, :active, :_destroy,
        maintenance_plan_item_services_attributes: [
          :id, :service_id, :quantity, :observation, :_destroy
        ]
      ]
    )
  end
end
