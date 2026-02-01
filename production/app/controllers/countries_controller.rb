class CountriesController < ApplicationController
  before_action :set_country, only: [:show, :edit, :update, :destroy, :get_country]

  def index
    authorize Country

    if params[:countries_grid].nil? || params[:countries_grid].blank?
      @countries = CountriesGrid.new(:current_user => @current_user)
      @countries_to_export = CountriesGrid.new(:current_user => @current_user)
    else
      @countries = CountriesGrid.new(params[:countries_grid].merge(current_user: @current_user))
      @countries_to_export = CountriesGrid.new(params[:countries_grid].merge(current_user: @current_user))
    end

    @countries.scope {|scope| scope.page(params[:page]) }

    respond_to do |format|
      format.html
      format.csv do
        send_data @countries_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"), 
        type: "text/csv", 
        disposition: 'inline', 
        filename: Country.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def new
    authorize Country
    @country = Country.new
    build_initial_relations
  end

  def edit
    authorize @country
    build_initial_relations
  end

  def create
    authorize Country
    @country = Country.new(country_params)
    if @country.save
      flash[:success] = t('flash.create')
      redirect_to countries_path
    else
      flash[:error] = @country.errors.full_messages.join('<br>')
      build_initial_relations
      render :new
    end
  end

  def update
    authorize @country
    @country.update(country_params)
    if @country.valid?
      flash[:success] = t('flash.update')
      redirect_to edit_country_path(@country)
    else
      flash[:error] = @country.errors.full_messages.join('<br>')
      build_initial_relations
      render :edit
    end
  end

  def destroy
    authorize @country
    if @country.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @country.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def build_initial_relations
  end

  def get_country
    data = {
      result: @country
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_country
    @country = Country.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white.
  def country_params
    params.require(:country).permit(:id, 
    :name
    )
  end
end
