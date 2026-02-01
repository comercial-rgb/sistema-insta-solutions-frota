class ProviderServiceTypesController < ApplicationController
  before_action :set_provider_service_type, only: [:show, :edit, :update, :destroy, :get_provider_service_type]

  def index
    authorize ProviderServiceType

    if params[:provider_service_types_grid].nil? || params[:provider_service_types_grid].blank?
      @provider_service_types = ProviderServiceTypesGrid.new(:current_user => @current_user)
      @provider_service_types_to_export = ProviderServiceTypesGrid.new(:current_user => @current_user)
    else
      @provider_service_types = ProviderServiceTypesGrid.new(params[:provider_service_types_grid].merge(current_user: @current_user))
      @provider_service_types_to_export = ProviderServiceTypesGrid.new(params[:provider_service_types_grid].merge(current_user: @current_user))
    end

    @provider_service_types.scope {|scope| scope.page(params[:page]) }

    respond_to do |format|
      format.html
      format.csv do
        send_data @provider_service_types_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"), 
        type: "text/csv", 
        disposition: 'inline', 
        filename: ProviderServiceType.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def new
    authorize ProviderServiceType
    @provider_service_type = ProviderServiceType.new
    build_initial_relations
  end

  def edit
    authorize @provider_service_type
    build_initial_relations
  end

  def create
    authorize ProviderServiceType
    @provider_service_type = ProviderServiceType.new(provider_service_type_params)
    if @provider_service_type.save
      flash[:success] = t('flash.create')
      redirect_to provider_service_types_path
    else
      flash[:error] = @provider_service_type.errors.full_messages.join('<br>')
      build_initial_relations
      render :new
    end
  end

  def update
    authorize @provider_service_type
    @provider_service_type.update(provider_service_type_params)
    if @provider_service_type.valid?
      flash[:success] = t('flash.update')
      redirect_to provider_service_types_path
    else
      flash[:error] = @provider_service_type.errors.full_messages.join('<br>')
      build_initial_relations
      render :edit
    end
  end

  def destroy
    authorize @provider_service_type
    if @provider_service_type.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @provider_service_type.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def build_initial_relations
    # if @provider_service_type.relations.select{ |item| item[:id].nil? }.length == 0
    #  @provider_service_type.relations.build
    # end
    # @provider_service_type.build_relation if @provider_service_type.relation.nil?
  end

  def get_provider_service_type
    data = {
      result: @provider_service_type
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_provider_service_type
    @provider_service_type = ProviderServiceType.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white.
  def provider_service_type_params
    params.require(:provider_service_type).permit(:id, 
    :name,
    :description,
    )
  end
end
