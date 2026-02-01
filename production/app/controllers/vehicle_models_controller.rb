class VehicleModelsController < ApplicationController
  before_action :set_vehicle_model, only: [:edit, :update, :destroy, :manage_prices, :update_prices]
  before_action :authorize_vehicle_model, except: [:index]

  def index
    authorize VehicleModel
    @grid = VehicleModelsGrid.new(params[:vehicle_models_grid]) do |scope|
      scope.page(params[:page])
    end
  end

  def manage_prices
    @services = Service.order(:name)
    @reference_prices = @vehicle_model.reference_prices.includes(:service).order('services.name')
    
    # Paginação para serviços disponíveis
    existing_service_ids = @reference_prices.pluck(:service_id)
    @available_services = @services.where.not(id: existing_service_ids).page(params[:page]).per(40)
  end

  def update_prices
    success_count = 0
    error_count = 0
    
    if params[:reference_prices].present?
      params[:reference_prices].each do |service_id, price_data|
        next if price_data[:reference_price].blank?
        
        reference_price = @vehicle_model.reference_prices.find_or_initialize_by(service_id: service_id)
        reference_price.assign_attributes(
          reference_price: price_data[:reference_price],
          max_percentage: price_data[:max_percentage] || 110,
          source: price_data[:source],
          active: price_data[:active] == '1'
        )
        
        if reference_price.save
          success_count += 1
        else
          error_count += 1
        end
      end
    end
    
    # Remove preços marcados para exclusão
    if params[:remove_prices].present?
      ids_to_remove = params[:remove_prices].select { |k, v| v == '1' }.keys
      @vehicle_model.reference_prices.where(service_id: ids_to_remove).destroy_all
    end
    
    if error_count == 0
      redirect_to manage_prices_vehicle_model_path(@vehicle_model), 
                  notice: "#{success_count} preço(s) atualizado(s) com sucesso."
    else
      redirect_to manage_prices_vehicle_model_path(@vehicle_model), 
                  alert: "#{success_count} salvos, #{error_count} com erro."
    end
  end

  def new
    @vehicle_model = VehicleModel.new
  end

  def create
    @vehicle_model = VehicleModel.new(vehicle_model_params)
    
    if @vehicle_model.save
      redirect_to vehicle_models_path, notice: 'Modelo de veículo criado com sucesso.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @vehicle_model.update(vehicle_model_params)
      redirect_to vehicle_models_path, notice: 'Modelo de veículo atualizado com sucesso.'
    else
      render :edit
    end
  end

  def destroy
    @vehicle_model.destroy
    redirect_to vehicle_models_path, notice: 'Modelo de veículo excluído com sucesso.'
  end

  private

  def set_vehicle_model
    @vehicle_model = VehicleModel.find(params[:id])
  end

  def authorize_vehicle_model
    authorize @vehicle_model || VehicleModel
  end

  def vehicle_model_params
    params.require(:vehicle_model).permit(
      :vehicle_type_id, :brand, :model, :version, 
      :full_name, :aliases, :code_cilia, :active
    )
  end
end
