class OrderServiceProposalsGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    # Excluir complementos da listagem principal - eles são mostrados dentro da proposta pai
    OrderServiceProposal.where(is_complement: [false, nil])
  end

  attr_accessor :current_user
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
    return current_user.admin? || current_user.provider?
  end

  def check_not_provider
    return !current_user.provider?
  end

  def check_provider
    return current_user.provider?
  end

  filter(:code, :string, if: :check_user, header: OrderService.human_attribute_name(:code)) do |value, relation, grid|
    relation.by_code(value)
  end

  filter(:provider_service_type_id, :enum, if: :check_user, select: proc { ProviderServiceType.order(:name).map {|c| [c.display_name, c.id] }}, header: OrderService.human_attribute_name(:provider_service_type_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_provider_service_type_id(value)
  end

  filter(:order_service_type_id, :enum, if: :check_user, select: proc { OrderServiceType.order(:name).map {|c| [c.name, c.id] }}, header: OrderService.human_attribute_name(:order_service_type_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_order_service_type_id(value)
  end

  filter(:created_at, :date, :range => true, if: :check_user, :header => OrderService.human_attribute_name(:created_at)) do |value, relation, grid|
    relation.by_initial_date(value[0]).by_final_date(value[1])
  end

  filter(:updated_at, :date, :range => true, if: :check_not_provider, :header => OrderService.human_attribute_name(:updated_at)) do |value, relation, grid|
    relation.by_initial_updated_at(value[0]).by_final_updated_at(value[1])
  end

  column(:code, order: 'order_services.code', if: :check_user, header: OrderService.human_attribute_name(:code) ) do |record, grid|
    if record.order_service
      record.order_service.code
    end
  end

  column(:client_id, if: :check_admin_or_provider, header: OrderService.human_attribute_name(:client_id) ) do |record, grid|
    if record.order_service && record.order_service.client
      record.order_service.client.fantasy_name
    end
  end

  column(:state_city, if: :check_admin, header: User.human_attribute_name(:state_city) ) do |record, grid|
    if record.order_service && record.order_service.client
      record.order_service.client.get_state_city_by_address
    end
  end

  column(:provider_service_type_id, if: :check_user, html: false, order: :provider_service_type_id, header: OrderService.human_attribute_name(:provider_service_type_id) ) do |record, grid|
    if record.order_service && record.order_service.provider_service_type
      record.order_service.provider_service_type.name
    end
  end

  column(:order_service_type_id, if: :check_user, html: false, order: :order_service_type_id, header: OrderService.human_attribute_name(:order_service_type_id) ) do |record, grid|
    if record.order_service && record.order_service.order_service_type
      record.order_service.order_service_type.name
    end
  end

  column(:order_service_type_id, html: true, if: :check_user, html: true, header: OrderService.human_attribute_name(:order_service_type_id) ) do |record, grid|
    if record.order_service
      render "order_services/order_service_type", record: record.order_service
    end
  end

  column(:cost_center, if: :check_not_provider, header: Vehicle.human_attribute_name(:cost_center) ) do |record, grid|
    if record.order_service && record.order_service.vehicle && record.order_service.vehicle.cost_center
      record.order_service.vehicle.cost_center.name
    end
  end

  column(:vehicle, if: :check_not_provider, html: true, header: OrderService.human_attribute_name(:vehicle) ) do |record, grid|
    if record.order_service
      render "order_services/show_vehicle_data", record: record.order_service
    end
  end

  column(:vehicle_id, if: :check_provider, html: false, header: OrderService.human_attribute_name(:vehicle_id) ) do |record, grid|
    if record.order_service && record.order_service.vehicle
      record.order_service.vehicle.getting_vehicle_data
    end
  end

  column(:vehicle_id, if: :check_provider, html: true, header: OrderService.human_attribute_name(:vehicle_id) ) do |record, grid|
    if record.order_service
      render "order_services/show_vehicle_data", record: record.order_service
    end
  end

  column(:created_at, if: :check_user, order: 'order_services.created_at', header: OrderService.human_attribute_name(:created_at) ) do |record, grid|
    CustomHelper.get_text_date(record.order_service.created_at, 'datetime', :full)
  end

  column(:total_value_without_discount, if: :check_user, order: 'order_service_proposals.total_value_without_discount', header: OrderServiceProposal.human_attribute_name(:total_value_without_discount) ) do |record, grid|
    CustomHelper.to_currency(record.total_value_without_discount)
  end

  column(:total_discount, if: :check_user, order: 'order_service_proposals.total_discount', header: OrderServiceProposal.human_attribute_name(:total_discount) ) do |record, grid|
    CustomHelper.to_currency(record.total_discount)
  end

  column(:total_value, if: :check_user, order: 'order_service_proposals.total_value', header: OrderServiceProposal.human_attribute_name(:total_value) ) do |record, grid|
    CustomHelper.to_currency(record.total_value)
  end

  column(:updated_at, if: :check_not_provider, order: 'order_services.updated_at', header: OrderService.human_attribute_name(:updated_at) ) do |record, grid|
    CustomHelper.get_text_date(record.order_service.updated_at, 'datetime', :full)
  end

  column(:order_service_status_id, html: false, if: :check_user, order: :order_service_status_id, header: OrderService.human_attribute_name(:order_service_status_id) ) do |record, grid|
    if record.order_service && record.order_service.order_service_status
      record.order_service.order_service_status.name
    end
  end

  column(:order_service_status_id, html: true, if: :check_user, html: true, header: '' ) do |record, grid|
    render "order_services/order_service_status", record: record.order_service, order_service_proposal: record
  end

  column(:actions, if: :check_not_provider, html: true, header: OrderServiceProposal.human_attribute_name(:actions) ) do |record, grid|
    render "datagrid_actions", record: record
  end

end
