class StatesController < ApplicationController
  before_action :set_state, only: [:show, :edit, :update, :destroy, :get_state]

  def index
    authorize State

    if params[:states_grid].nil? || params[:states_grid].blank?
      @states = StatesGrid.new(:current_user => @current_user)
      @states_to_export = StatesGrid.new(:current_user => @current_user)
    else
      @states = StatesGrid.new(params[:states_grid].merge(current_user: @current_user))
      @states_to_export = StatesGrid.new(params[:states_grid].merge(current_user: @current_user))
    end

    @states.scope {|scope| scope.page(params[:page]) }

    respond_to do |format|
      format.html
      format.csv do
        send_data @states_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"), 
        type: "text/csv", 
        disposition: 'inline', 
        filename: State.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def new
    authorize State
    @state = State.new
    build_initial_relations
  end

  def edit
    authorize @state
    build_initial_relations
  end

  def create
    authorize State
    @state = State.new(state_params)
    if @state.save
      flash[:success] = t('flash.create')
      redirect_to states_path
    else
      flash[:error] = @state.errors.full_messages.join('<br>')
      build_initial_relations
      render :new
    end
  end

  def update
    authorize @state
    @state.update(state_params)
    if @state.valid?
      flash[:success] = t('flash.update')
      redirect_to edit_state_path(@state)
    else
      flash[:error] = @state.errors.full_messages.join('<br>')
      build_initial_relations
      render :edit
    end
  end

  def destroy
    authorize @state
    if @state.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @state.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def build_initial_relations
  end

  def get_state
    data = {
      result: @state
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def by_country
    data = State.where('country_id = ?', params[:country_id]).order(:name)
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_state
    @state = State.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white.
  def state_params
    params.require(:state).permit(:id, 
    :name,
    :acronym,
    :country_id
    )
  end
end
