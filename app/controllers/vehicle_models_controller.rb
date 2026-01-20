class VehicleModelsController < ApplicationController
  before_action :set_vehicle_model, only: [:edit, :update, :destroy]
  before_action :authorize_vehicle_model, except: [:index]

  def index
    authorize VehicleModel
    @grid = VehicleModelsGrid.new(params[:vehicle_models_grid]) do |scope|
      scope.page(params[:page])
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
