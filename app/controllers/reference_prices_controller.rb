class ReferencePricesController < ApplicationController
  before_action :set_reference_price, only: [:edit, :update, :destroy]
  before_action :authorize_reference_price, except: [:index]

  def index
    authorize ReferencePrice
    @grid = ReferencePricesGrid.new(params[:reference_prices_grid]) do |scope|
      scope.page(params[:page])
    end
  end

  def new
    @reference_price = ReferencePrice.new
  end

  def create
    @reference_price = ReferencePrice.new(reference_price_params)
    
    if @reference_price.save
      redirect_to reference_prices_path, notice: 'Preço de referência criado com sucesso.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @reference_price.update(reference_price_params)
      redirect_to reference_prices_path, notice: 'Preço de referência atualizado com sucesso.'
    else
      render :edit
    end
  end

  def destroy
    @reference_price.destroy
    redirect_to reference_prices_path, notice: 'Preço de referência excluído com sucesso.'
  end

  private

  def set_reference_price
    @reference_price = ReferencePrice.find(params[:id])
  end

  def authorize_reference_price
    authorize @reference_price || ReferencePrice
  end

  def reference_price_params
    params.require(:reference_price).permit(
      :vehicle_model_id, :service_id, :reference_price, 
      :max_percentage, :observation, :source, :active
    )
  end
end
