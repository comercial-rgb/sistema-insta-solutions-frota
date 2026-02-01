class ServicesController < ApplicationController
  before_action :set_service, only: [:show, :edit, :update, :destroy, :get_service]

  def index
    authorize Service

    if params[:services_grid].nil? || params[:services_grid].blank?
      @services = ServicesGrid.new(:current_user => @current_user)
      @services_to_export = ServicesGrid.new(:current_user => @current_user)
    else
      @services = ServicesGrid.new(params[:services_grid].merge(current_user: @current_user))
      @services_to_export = ServicesGrid.new(params[:services_grid].merge(current_user: @current_user))
    end

    if @current_user.admin?
      @services.scope {|scope| scope.page(params[:page]) }
    elsif @current_user.provider?
      @services.scope {|scope| scope.by_provider_id(@current_user.id).page(params[:page]) }
      @services_to_export.scope {|scope| scope.by_provider_id(@current_user.id) }
    end

    respond_to do |format|
      format.html
      format.csv do
        # Exportar no formato compatível com importação (template)
        csv_data = generate_importable_csv(@services_to_export)
        send_data csv_data.encode("UTF-8"),
        type: "text/csv; charset=utf-8",
        disposition: 'attachment',
        filename: "pecas_servicos_#{Date.today.strftime('%Y%m%d')}.csv"
      end
    end
  end

  def new
    authorize Service
    @service = Service.new
    build_initial_relations
  end

  def edit
    authorize @service
    build_initial_relations
  end

  def create
    authorize Service
    @service = Service.new(service_params)
    if service_params[:category_id] == Category::SERVICOS_PECAS
      @service.category_id = Category::SERVICOS_PECAS_ID
    elsif service_params[:category_id] == Category::SERVICOS_SERVICOS
      @service.category_id = Category::SERVICOS_SERVICOS_ID
    end
    @service.provider_id = @current_user.id if @current_user.provider?

    respond_to do |format|
      if @service.save
        format.html do
          flash[:success] = t('flash.create')
          redirect_to services_path
        end

        format.json do
          render json: { id: @service.id, name: @service.name, category_id: @service.category_id }, status: :created
        end
      else
        format.html do
          flash[:error] = @service.errors.full_messages.join('<br>')
          build_initial_relations
          render :new
        end

        format.json do
          render json: { errors: @service.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    authorize @service
    @service.update(service_params)
    if @service.valid?
      flash[:success] = t('flash.update')
      redirect_to services_path
    else
      flash[:error] = @service.errors.full_messages.join('<br>')
      build_initial_relations
      render :edit
    end
  end

  def destroy
    authorize @service
    if @service.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @service.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def build_initial_relations
    # if @service.relations.select{ |item| item[:id].nil? }.length == 0
    #  @service.relations.build
    # end
    # @service.build_relation if @service.relation.nil?
  end

  def get_service
    data = {
      result: @service
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def getting_service_values
    data = Service.getting_values_with_discount(params[:service_id], params[:client_id], params[:quantity])
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def getting_service_values_new_product
    data = Service.getting_values_with_discount_new_product(params[:client_id], params[:price], params[:quantity])
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def by_category
    authorize Service, :by_category?
    
    category_id = params[:category_id]
    
    begin
      services = Service.where(category_id: category_id).order(:name)
      
      data = services.map do |service|
        {
          id: service.id,
          name: service.name,
          price: service.price,
          category_id: service.category_id
        }
      end
      
      render json: data, status: 200
    rescue => e
      Rails.logger.error "Erro em by_category: #{e.message}"
      render json: { error: e.message }, status: 500
    end
  end

  # Gera CSV no formato de template (compatível com importação)
  def generate_importable_csv(grid)
    require 'csv'
    
    CSV.generate(col_sep: ';', encoding: 'UTF-8') do |csv|
      # Cabeçalho no formato de importação
      csv << ['nome', 'categoria', 'codigo', 'preco']
      
      # Dados dos serviços existentes
      grid.assets.each do |service|
        category_name = case service.category_id
        when Category::SERVICOS_PECAS_ID
          'peca'
        when Category::SERVICOS_SERVICOS_ID
          'servico'
        else
          ''
        end
        
        csv << [
          service.name,
          category_name,
          service.code || '',
          service.price ? sprintf('%.2f', service.price).gsub('.', ',') : '0,00'
        ]
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_service
    @service = Service.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white.
  def service_params
    params.require(:service).permit(:id,
    :name,
    :category_id,
    :image,
    :description,
    :price,
    :provider_id,
    :code,
    :warranty_period,
    :brand
    )
  end
end
