class ServiceGroupsController < ApplicationController
  before_action :set_service_group, only: [:show, :edit, :update, :destroy]

  def index
    authorize ServiceGroup

    @service_groups = ServiceGroupsGrid.new(params[:service_groups_grid]) do |scope|
      scope.page(params[:page])
    end

    @service_groups_to_export = ServiceGroupsGrid.new(params[:service_groups_grid]) do |scope|
      scope
    end

    respond_to do |format|
      format.html
      format.csv do
        send_data @service_groups_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: ServiceGroup.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
    end
  end

  def show
    authorize @service_group
    respond_to do |format|
      format.json { 
        render json: @service_group.as_json(
          only: [:id, :name, :active],
          include: {
            service_group_items: {
              only: [:id, :service_id, :quantity, :max_value],
              include: {
                service: { only: [:id, :name, :category_id, :price] }
              }
            }
          }
        )
      }
    end
  end

  # Retorna os IDs dos serviços permitidos em um grupo
  def services
    authorize ServiceGroup
    @service_group = ServiceGroup.find(params[:id])
    service_ids = @service_group.service_group_items.pluck(:service_id)
    
    respond_to do |format|
      format.json { render json: { service_ids: service_ids } }
    end
  end

  def new
    authorize ServiceGroup
    @service_group = ServiceGroup.new
    @service_group.service_group_items.build # Adiciona um item em branco
    @services = Service.all
  end

  def edit
    authorize @service_group
    @service_group.service_group_items.build if @service_group.service_group_items.empty? # Adiciona um item em branco se não tiver nenhum
    @services = Service.all
  end

  def create
    authorize ServiceGroup
    @service_group = ServiceGroup.new(service_group_params)
    if @service_group.save
      flash[:success] = t('flash.create')
      redirect_to service_groups_path
    else
      flash[:error] = @service_group.errors.full_messages.join('<br>')
      render :new
    end
  end

  def update
    authorize @service_group
    @service_group.update(service_group_params)
    if @service_group.valid?
      flash[:success] = t('flash.update')
      redirect_to service_groups_path
    else
      flash[:error] = @service_group.errors.full_messages.join('<br>')
      render :edit
    end
  end

  def destroy
    authorize @service_group
    if @service_group.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @service_group.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  private

  def set_service_group
    @service_group = ServiceGroup.find(params[:id])
  end

  def service_group_params
    permitted_params = params.require(:service_group).permit(
      :name, 
      :value_limit, 
      :active,
      client_ids: [],
      service_group_items_attributes: [:id, :service_id, :quantity, :max_value, :_destroy]
    )
    
    # Normalizar valores monetários dos itens
    if permitted_params[:service_group_items_attributes]
      permitted_params[:service_group_items_attributes].each do |key, item_attrs|
        if item_attrs[:max_value].present? && item_attrs[:max_value].is_a?(String)
          item_attrs[:max_value] = item_attrs[:max_value].gsub('R$', '').gsub(' ', '').gsub('.', '').gsub(',', '.').strip
        end
      end
    end
    
    permitted_params
  end
end
