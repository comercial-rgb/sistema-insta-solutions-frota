class VehicleTypesController < ApplicationController
  before_action :set_vehicle_type, only: [:show, :edit, :update, :destroy, :get_vehicle_type]

  def index
    authorize VehicleType

    if params[:vehicle_types_grid].nil? || params[:vehicle_types_grid].blank?
      @vehicle_types = VehicleTypesGrid.new(:current_user => @current_user)
      @vehicle_types_to_export = VehicleTypesGrid.new(:current_user => @current_user)
    else
      @vehicle_types = VehicleTypesGrid.new(params[:vehicle_types_grid].merge(current_user: @current_user))
      @vehicle_types_to_export = VehicleTypesGrid.new(params[:vehicle_types_grid].merge(current_user: @current_user))
    end

    @vehicle_types.scope {|scope| scope.page(params[:page]) }

    respond_to do |format|
      format.html
      format.csv do
        send_data @vehicle_types_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"), 
        type: "text/csv", 
        disposition: 'inline', 
        filename: VehicleType.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def new
    authorize VehicleType
    @vehicle_type = VehicleType.new
    build_initial_relations
  end

  def edit
    authorize @vehicle_type
    build_initial_relations
  end

  def create
    authorize VehicleType
    @vehicle_type = VehicleType.new(vehicle_type_params)
    if @vehicle_type.save
      flash[:success] = t('flash.create')
      redirect_to vehicle_types_path
    else
      flash[:error] = @vehicle_type.errors.full_messages.join('<br>')
      build_initial_relations
      render :new
    end
  end

  def update
    authorize @vehicle_type
    @vehicle_type.update(vehicle_type_params)
    if @vehicle_type.valid?
      flash[:success] = t('flash.update')
      redirect_to vehicle_types_path
    else
      flash[:error] = @vehicle_type.errors.full_messages.join('<br>')
      build_initial_relations
      render :edit
    end
  end

  def destroy
    authorize @vehicle_type
    if @vehicle_type.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @vehicle_type.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def build_initial_relations
    # if @vehicle_type.relations.select{ |item| item[:id].nil? }.length == 0
    #  @vehicle_type.relations.build
    # end
    # @vehicle_type.build_relation if @vehicle_type.relation.nil?
  end

  def get_vehicle_type
    data = {
      result: @vehicle_type
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_vehicle_type
    @vehicle_type = VehicleType.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white.
  def vehicle_type_params
    params.require(:vehicle_type).permit(:id, 
    :name,
    )
  end
end
