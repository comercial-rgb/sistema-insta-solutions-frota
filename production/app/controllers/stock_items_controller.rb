class StockItemsController < ApplicationController
  before_action :set_stock_item, only: [:show, :edit, :update, :destroy, :movement_history, :adjust_stock]
  before_action :set_filter_data, only: [:index, :new, :edit, :dashboard]

  def index
    authorize StockItem
    @stock_items_grid = StockItemsGrid.new(params[:stock_items_grid]) do |scope|
      scope_for_user(scope).page(params[:page])
    end
    @stock_items_grid.current_user = @current_user
    @stock_items = @stock_items_grid.assets

    respond_to do |format|
      format.html
      format.csv { send_data @stock_items_grid.to_csv, filename: "estoque_#{Date.today}.csv" }
    end
  end

  def dashboard
    authorize StockItem, :index?
    base_scope = scope_for_user(StockItem.all)

    @total_items = base_scope.count
    @total_value = base_scope.sum("quantity * unit_price")
    @items_below_minimum = base_scope.below_minimum_stock.count
    @items_without_stock = base_scope.where(quantity: 0).count
    @items_with_stock = base_scope.with_stock.count

    @recent_movements = StockMovement
      .joins(:stock_item)
      .where(stock_items: { id: base_scope.select(:id) })
      .order(created_at: :desc)
      .limit(10)
      .includes(:user, :stock_item)

    @items_below_minimum_list = base_scope.below_minimum_stock.limit(10).includes(:cost_center, :sub_unit)

    # Movimentações dos últimos 30 dias para gráfico
    @movements_chart_data = StockMovement
      .joins(:stock_item)
      .where(stock_items: { id: base_scope.select(:id) })
      .where("stock_movements.created_at >= ?", 30.days.ago)
      .group("DATE(stock_movements.created_at)")
      .group(:movement_type)
      .count
  end

  def show
    authorize @stock_item
    @movements = @stock_item.stock_movements.order(created_at: :desc).page(params[:page]).per(20)
  end

  def new
    authorize StockItem
    @stock_item = StockItem.new
  end

  def create
    authorize StockItem
    @stock_item = StockItem.new(stock_item_params)
    @stock_item.created_by = @current_user

    # Define client_id baseado no perfil
    if @current_user.admin?
      @stock_item.client_id = params[:stock_item][:client_id]
    else
      @stock_item.client_id = @current_user.client_id || @current_user.id
    end

    if @stock_item.save
      # Se uma quantidade inicial foi informada, registrar como entrada
      if @stock_item.quantity > 0
        @stock_item.stock_movements.create!(
          user: @current_user,
          movement_type: :entry,
          quantity: @stock_item.quantity,
          unit_price: @stock_item.unit_price,
          balance_after: @stock_item.quantity,
          reason: 'Estoque inicial',
          source: :manual
        )
      end
      redirect_to stock_item_path(@stock_item), notice: t('flash.created', model: StockItem.model_name.human)
    else
      set_filter_data
      render :new
    end
  end

  def edit
    authorize @stock_item
  end

  def update
    authorize @stock_item
    @stock_item.updated_by = @current_user

    if @stock_item.update(stock_item_params.except(:quantity))
      redirect_to stock_item_path(@stock_item), notice: t('flash.updated', model: StockItem.model_name.human)
    else
      set_filter_data
      render :edit
    end
  end

  def destroy
    authorize @stock_item
    if @stock_item.stock_order_service_items.any?
      redirect_to stock_items_path, alert: 'Não é possível excluir item com vínculos em Ordens de Serviço.'
    else
      @stock_item.destroy
      redirect_to stock_items_path, notice: t('flash.destroyed', model: StockItem.model_name.human)
    end
  end

  def movement_history
    authorize @stock_item, :show?
    @movements = @stock_item.stock_movements.order(created_at: :desc).page(params[:page]).per(20)
  end

  def adjust_stock
    authorize @stock_item, :update?
    new_quantity = params[:new_quantity].to_f
    reason = params[:reason]

    if reason.blank?
      redirect_to stock_item_path(@stock_item), alert: 'Informe o motivo do ajuste.'
      return
    end

    if @stock_item.adjust_stock(new_quantity, @current_user, reason)
      redirect_to stock_item_path(@stock_item), notice: 'Estoque ajustado com sucesso.'
    else
      redirect_to stock_item_path(@stock_item), alert: 'Erro ao ajustar estoque.'
    end
  end

  def import_xml
    authorize StockItem, :create?

    if params[:xml_file].blank?
      redirect_to new_import_xml_stock_items_path, alert: 'Selecione um arquivo XML.'
      return
    end

    xml_file = params[:xml_file]
    allowed_xml_types = %w[text/xml application/xml]
    ext = File.extname(xml_file.original_filename.to_s).downcase
    unless ext == '.xml' && allowed_xml_types.include?(xml_file.content_type.to_s.split(';').first.strip)
      redirect_to new_import_xml_stock_items_path, alert: 'Formato inválido. Envie apenas arquivos XML (NF-e).'
      return
    end

    service = StockXmlImportService.new(
      xml_file: params[:xml_file],
      client_id: resolve_client_id,
      cost_center_id: params[:cost_center_id],
      sub_unit_id: params[:sub_unit_id],
      user: @current_user
    )

    result = service.parse

    if result[:success] && result[:items].any?
      session[:xml_import_preview] = {
        items: result[:items],
        supplier_name: result[:supplier_name],
        supplier_cnpj: result[:supplier_cnpj],
        document_number: result[:document_number],
        xml_file_name: result[:xml_file_name],
        cost_center_id: params[:cost_center_id],
        sub_unit_id: params[:sub_unit_id]
      }.to_json
      @preview = result
      @cost_center_id = params[:cost_center_id]
      @available_parents = StockItem.active.where(client_id: resolve_client_id, cost_center_id: params[:cost_center_id]).order(:name)
      render :preview_import_xml
    else
      errors = result[:errors].any? ? result[:errors].join(', ') : 'Nenhum item encontrado no XML.'
      redirect_to new_import_xml_stock_items_path, alert: "Erro na importação: #{errors}"
    end
  end

  def confirm_import_xml
    authorize StockItem, :create?

    preview_json = session[:xml_import_preview]
    if preview_json.blank?
      redirect_to new_import_xml_stock_items_path, alert: 'Sessão expirada. Por favor, reimporte o arquivo.'
      return
    end

    preview = JSON.parse(preview_json, symbolize_names: true)
    items_params = params[:items]&.values || []

    # Merge item data from session with user inputs (minimum_quantity, parent_stock_item_id)
    merged_items = preview[:items].each_with_index.map do |item, idx|
      user_input = items_params[idx] || {}
      item.merge(
        minimum_quantity: user_input[:minimum_quantity].presence || item[:minimum_quantity],
        parent_stock_item_id: user_input[:parent_stock_item_id].presence
      )
    end

    service = StockXmlImportService.new(
      xml_file: nil,
      client_id: resolve_client_id,
      cost_center_id: preview[:cost_center_id],
      sub_unit_id: preview[:sub_unit_id],
      user: @current_user
    )

    result = service.confirm(
      items_params: merged_items,
      supplier_name: preview[:supplier_name],
      supplier_cnpj: preview[:supplier_cnpj],
      document_number: preview[:document_number],
      xml_file_name: preview[:xml_file_name]
    )

    session.delete(:xml_import_preview)

    if result[:success]
      redirect_to stock_items_path, notice: "Importação concluída: #{result[:imported]} itens importados, #{result[:updated]} atualizados."
    else
      redirect_to new_import_xml_stock_items_path, alert: "Erro na importação: #{result[:errors].join(', ')}"
    end
  end

  def new_import_xml
    authorize StockItem, :create?
    set_filter_data
  end

  # AJAX endpoint: stock items by cost_center
  def by_cost_center
    authorize StockItem, :index?
    cost_center_id = params[:cost_center_id]
    sub_unit_id = params[:sub_unit_id]

    items = StockItem.active.by_cost_center_id(cost_center_id)
    items = items.by_sub_unit_id(sub_unit_id) if sub_unit_id.present?
    items = items.with_stock

    render json: items.map { |item|
      {
        id: item.id,
        name: item.formatted_name_with_stock,
        quantity: item.quantity,
        unit_price: item.unit_price,
        unit_measure: item.unit_measure
      }
    }
  end

  private

  def set_stock_item
    @stock_item = StockItem.find(params[:id])
  end

  def stock_item_params
    params.require(:stock_item).permit(
      :name, :code, :brand, :description, :quantity, :minimum_quantity,
      :unit_price, :unit_measure, :ncm, :part_number, :location,
      :status, :category_id, :cost_center_id, :sub_unit_id, :client_id
    )
  end

  def set_filter_data
    if @current_user.admin?
      @clients = User.where(profile_id: Profile::CLIENT_ID).order(:name)
      @cost_centers = CostCenter.all.order(:name)
      @sub_units = SubUnit.all.order(:name)
    elsif @current_user.manager? || @current_user.additional?
      @clients = []
      client_id = @current_user.client_id || @current_user.id
      @cost_centers = @current_user.associated_cost_centers.any? ?
        @current_user.associated_cost_centers.order(:name) :
        CostCenter.where(client_id: client_id).order(:name)
      @sub_units = @current_user.associated_sub_units.any? ?
        @current_user.associated_sub_units.order(:name) :
        SubUnit.joins(:cost_center).where(cost_centers: { client_id: client_id }).order(:name)
    else
      @clients = []
      @cost_centers = []
      @sub_units = []
    end
    @categories = Category.where(category_type_id: CategoryType::SERVICOS_ID).order(:name) rescue Category.all.order(:name)
  end

  def scope_for_user(scope)
    if @current_user.admin?
      scope
    elsif @current_user.manager? || @current_user.additional?
      client_id = @current_user.client_id || @current_user.id
      cost_center_ids = @current_user.associated_cost_centers.map(&:id)
      sub_unit_ids = @current_user.associated_sub_units.map(&:id)

      if cost_center_ids.any? || sub_unit_ids.any?
        scope.by_client_id(client_id).by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
      else
        scope.by_client_id(client_id)
      end
    else
      scope.none
    end
  end

  def resolve_client_id
    if @current_user.admin?
      params[:client_id]
    else
      @current_user.client_id || @current_user.id
    end
  end
end
