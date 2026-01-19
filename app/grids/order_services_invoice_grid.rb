class OrderServicesInvoiceGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    OrderService.all
  end

  attr_accessor :current_user,
  :clients, :managers, :cost_centers,
  :vehicles, :provider_service_types,
  :order_service_types, :current_order_service_status_id,
  :providers, :show_order_service_status,
  :period_filter, :method, :commitments, :sub_units

  # grid.current_user para acessar o usuário
  # grid[:id] para acessar o filtro atual (no id, por exemplo)
  # grid[:created_at][0] para acessar o filtro atual quando for range true

  def check_user
    # return (!current_user.user?)
    return true
  end

  def check_admin
    return current_user.admin?
  end

  def check_admin_or_provider
    return (current_user.admin? || current_user.provider?)
  end

  def check_not_provider
    return !current_user.provider?
  end

  def check_provider
    return current_user.provider?
  end

  def check_show_order_service_status
    return !show_order_service_status.nil? && show_order_service_status
  end

  def check_show_actions
    return show_order_service_status.nil? || !show_order_service_status
  end

  # def get_cost_centers
  #   return CostCenter.getting_data_by_user(current_user).map {|c| [c.name, c.id] }
  # end

  # def get_vehicles
  #   return Vehicle.getting_data_by_user(current_user).map {|c| [c.board, c.id] }
  # end

  def get_vehicles
    return vehicles
  end

  def get_clients
    return clients
  end

  def get_managers
    return managers
  end

  def get_cost_centers
    return cost_centers
  end

  def get_provider_service_types
    return provider_service_types
  end

  def get_order_service_types
    return order_service_types
  end

  def get_providers
    return providers
  end

  def check_select_all
    if [OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID, OrderServiceStatus::AUTORIZADA_ID, OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID].include?(current_order_service_status_id)
      return (current_user.admin? || (!current_user.admin? && current_order_service_status_id == OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID))
    else
      return false
    end
  end

  def show_period_filter
    return !period_filter.nil? && period_filter
  end

  filter(:month, :enum, if: :show_period_filter, select: CustomHelper.get_months_options, header: OrderService.human_attribute_name(:month), include_blank: false, default: Date.today.month ) do |value, relation, grid|
    # O filtro de ano aplicará o scope approved_in_period
    relation
  end

  filter(:year, :enum, if: :show_period_filter, select: CustomHelper.get_years(2024, Date.today.year), header: OrderService.human_attribute_name(:year), include_blank: false, default: Date.today.year ) do |value, relation, grid|
    # Aplicar filtro de OSs aprovadas no mês/ano selecionado (apenas aqui para evitar duplicação)
    if grid.month.present? && value.present?
      start_date = Date.new(value.to_i, grid.month.to_i, 1).beginning_of_month.strftime('%Y-%m-%d')
      end_date = Date.new(value.to_i, grid.month.to_i, 1).end_of_month.strftime('%Y-%m-%d')
      relation.approved_in_period(start_date, end_date)
    else
      relation
    end
  end

  filter(:client_id, :enum, if: :check_admin_or_provider, select: :get_clients, header: OrderService.human_attribute_name(:client_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_client_id(value)
  end

  filter(:manager_id, :enum, if: false, select: :get_managers, header: OrderService.human_attribute_name(:manager_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_manager_id(value)
  end

  filter(:provider_id, :enum, if: :check_admin, select: :get_providers, header: OrderService.human_attribute_name(:provider_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_proposal_provider_id(value)
  end

  filter(:cost_center_id, :enum, if: :check_not_provider, select: :get_cost_centers, header: OrderService.human_attribute_name(:cost_center_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_cost_center_id(value)
  end

  filter(:vehicle_id, :enum, if: false, select: :get_vehicles, header: OrderService.human_attribute_name(:vehicle_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_vehicle_id(value)
  end

  filter(:provider_service_type_id, :enum, if: false, select: :get_provider_service_types, header: OrderService.human_attribute_name(:provider_service_type_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_provider_service_type_id(value)
  end

  filter(:order_service_type_id, :enum, if: false, select: :get_order_service_types, header: OrderService.human_attribute_name(:order_service_type_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_order_service_type_id(value)
  end

  filter(:order_service_status_id, :enum, if: false, select: proc { OrderServiceStatus.order(:id).map {|c| [c.name, c.id] }}, header: OrderService.human_attribute_name(:order_service_status_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_order_service_status_id(value)
  end

  filter(:code, :string, if: false, header: OrderService.human_attribute_name(:code)) do |value, relation, grid|
    relation.by_code(value)
  end

  filter(:created_at, :date, :range => true, if: false, :header => OrderService.human_attribute_name(:created_at)) do |value, relation, grid|
    relation.by_initial_date(value[0]).by_final_date(value[1])
  end

  filter(:updated_at, :date, :range => true, if: false, :header => OrderService.human_attribute_name(:updated_at)) do |value, relation, grid|
    relation.by_initial_updated_at(value[0]).by_final_updated_at(value[1])
  end

  column(:select_register, if: :check_select_all, html: true, header: "#" ) do |record, grid|
    render "common_pages/datagrid/select_register", record: record, current_model: "order-service"
  end

  column(:client_id, if: :check_admin_or_provider, order: :client_id, header: OrderService.human_attribute_name(:client_id) ) do |record, grid|
    if record.client
      record.client.fantasy_name
    end
  end

  column(:code, order: :code, if: :check_user, header: OrderService.human_attribute_name(:code) ) do |record, grid|
    record.code
  end

  column(:vehicle_id, if: :check_admin_or_provider, header: Vehicle.human_attribute_name(:board) ) do |record, grid|
    if record.vehicle
      record.vehicle.board
    end
  end

  column(:vehicle_id, if: :check_admin_or_provider, header: Vehicle.human_attribute_name(:brand) ) do |record, grid|
    if record.vehicle
      record.vehicle.brand
    end
  end

  column(:vehicle_id, if: :check_admin_or_provider, header: Vehicle.human_attribute_name(:model) ) do |record, grid|
    if record.vehicle
      record.vehicle.model
    end
  end

  column(:provider_id, if: :check_admin, order: :provider_id, header: OrderService.human_attribute_name(:provider_id) ) do |record, grid|
    if record.provider
      record.provider.name
    end
  end

end
