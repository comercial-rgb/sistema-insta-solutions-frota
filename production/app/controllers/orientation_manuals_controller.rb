class OrientationManualsController < ApplicationController
  before_action :set_orientation_manual, only: [:show, :edit, :update, :destroy, :get_orientation_manual]

  def index
    authorize OrientationManual

    if params[:orientation_manuals_grid].nil? || params[:orientation_manuals_grid].blank?
      @orientation_manuals = OrientationManualsGrid.new(:current_user => @current_user)
      @orientation_manuals_to_export = OrientationManualsGrid.new(:current_user => @current_user)
    else
      @orientation_manuals = OrientationManualsGrid.new(params[:orientation_manuals_grid].merge(current_user: @current_user))
      @orientation_manuals_to_export = OrientationManualsGrid.new(params[:orientation_manuals_grid].merge(current_user: @current_user))
    end

    if @current_user.admin?
      @orientation_manuals.scope {|scope| scope.page(params[:page]) }
    else
      @orientation_manuals.scope {|scope| scope.by_profile_id(@current_user.profile_id).page(params[:page]) }
      @orientation_manuals_to_export.scope {|scope| scope.by_profile_id(@current_user.profile_id) }
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data @orientation_manuals_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: OrientationManual.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def new
    authorize OrientationManual
    @orientation_manual = OrientationManual.new
    build_initial_relations
  end

  def edit
    authorize @orientation_manual
    build_initial_relations
  end

  def create
    authorize OrientationManual
    @orientation_manual = OrientationManual.new(orientation_manual_params)
    if @orientation_manual.save
      flash[:success] = t('flash.create')
      redirect_to orientation_manuals_path
    else
      flash[:error] = @orientation_manual.errors.full_messages.join('<br>')
      build_initial_relations
      render :new
    end
  end

  def update
    authorize @orientation_manual
    @orientation_manual.update(orientation_manual_params)
    if @orientation_manual.valid?
      flash[:success] = t('flash.update')
      redirect_to orientation_manuals_path
    else
      flash[:error] = @orientation_manual.errors.full_messages.join('<br>')
      build_initial_relations
      render :edit
    end
  end

  def destroy
    authorize @orientation_manual
    if @orientation_manual.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @orientation_manual.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def build_initial_relations
    # if @orientation_manual.relations.select{ |item| item[:id].nil? }.length == 0
    #  @orientation_manual.relations.build
    # end
    # @orientation_manual.build_relation if @orientation_manual.relation.nil?
  end

  def get_orientation_manual
    data = {
      result: @orientation_manual
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_orientation_manual
    @orientation_manual = OrientationManual.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white.
  def orientation_manual_params
    params.require(:orientation_manual).permit(:id,
    :name,
    :description,
    :document,
    profile_ids: []
    )
  end
end
