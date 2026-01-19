class CitiesController < ApplicationController
  before_action :set_city, only: [:show, :edit, :update, :destroy, :get_city]
  skip_before_action :authenticate_user, only: [:by_state]

  def index
    authorize City

    if params[:cities_grid].nil? || params[:cities_grid].blank?
      @cities = CitiesGrid.new(:current_user => @current_user)
      @cities_to_export = CitiesGrid.new(:current_user => @current_user)
    else
      @cities = CitiesGrid.new(params[:cities_grid].merge(current_user: @current_user))
      @cities_to_export = CitiesGrid.new(params[:cities_grid].merge(current_user: @current_user))
    end

    @cities.scope {|scope| scope.page(params[:page]) }

    respond_to do |format|
      format.html
      format.csv do
        send_data @cities_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"), 
        type: "text/csv", 
        disposition: 'inline', 
        filename: City.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def new
    authorize City
    @city = City.new
    build_initial_relations
  end

  def edit
    authorize @city
    build_initial_relations
  end

  def create
    authorize City
    @city = City.new(city_params)
    if @city.save
      flash[:success] = t('flash.create')
      redirect_to cities_path
    else
      flash[:error] = @city.errors.full_messages.join('<br>')
      build_initial_relations
      render :new
    end
  end

  def update
    authorize @city
    @city.update(city_params)
    if @city.valid?
      flash[:success] = t('flash.update')
      redirect_to edit_city_path(@city)
    else
      flash[:error] = @city.errors.full_messages.join('<br>')
      build_initial_relations
      render :edit
    end
  end

  def destroy
    authorize @city
    if @city.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @city.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def build_initial_relations
  end

  def get_city
    data = {
      result: @city
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def by_state
  	data = City.where('state_id = ?', params[:state_id]).order(:name)
  	respond_to do |format|
  		format.json {render :json => data, :status => 200}
  	end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_city
    @city = City.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white.
  def city_params
    params.require(:city).permit(:id, 
    :name,
    :state_id,
    :country_id,
    :latitude,
    :longitude,
    :ibge_code,
    :quantity_population
    )
  end
end
