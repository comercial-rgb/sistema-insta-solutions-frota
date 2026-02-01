class VehiclesGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    Vehicle.all
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

  def getting_cost_centers
    return CostCenter.getting_data_by_user(current_user).map {|c| [c.name, c.id] }
  end

  def getting_sub_units
    return SubUnit.getting_data_by_user(current_user, nil).map {|c| [c.name, c.id] }
  end

  filter(:client_id, :enum, if: :check_admin, select: proc { User.client.order(:fantasy_name).map {|c| [c.fantasy_name, c.id] }}, header: Vehicle.human_attribute_name(:client_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_client_id(value)
  end

  filter(:cost_center_id, :enum, if: :check_user, select: :getting_cost_centers, header: Vehicle.human_attribute_name(:cost_center_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_cost_center_id(value)
  end

  filter(:sub_unit_id, :enum, if: :check_user, select: :getting_sub_units, header: Vehicle.human_attribute_name(:sub_unit_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_sub_unit_id(value)
  end

  filter(:state_id, :enum, if: :check_user, select: proc { State.order(:name).map {|c| [c.acronym, c.id] }}, header: Vehicle.human_attribute_name(:state_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_state_id(value)
  end

  filter(:city_id, :enum, if: :check_user, select: proc { City.order(:name).map {|c| [c.name, c.id] }}, header: Vehicle.human_attribute_name(:city_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_city_id(value)
  end

  filter(:fuel_type_id, :enum, if: :check_user, select: proc { FuelType.order(:id).map {|c| [c.name, c.id] }}, header: Vehicle.human_attribute_name(:fuel_type_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_fuel_type_id(value)
  end

  filter(:active, :enum, if: :check_user, select: CustomHelper.return_select_options_yes_no, header: Vehicle.human_attribute_name(:active), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_active(value)
  end

  filter(:board, :string, if: :check_user, header: Vehicle.human_attribute_name(:board)) do |value, relation, grid|
    relation.by_board(value)
  end

  filter(:brand, :string, if: :check_user, header: Vehicle.human_attribute_name(:brand)) do |value, relation, grid|
    relation.by_brand(value)
  end

  filter(:model, :string, if: :check_user, header: Vehicle.human_attribute_name(:model)) do |value, relation, grid|
    relation.by_model(value)
  end

  filter(:year, :string, if: :check_user, header: Vehicle.human_attribute_name(:year)) do |value, relation, grid|
    relation.by_year(value)
  end

  filter(:maintenance_value, :integer, :range => true, if: :check_user, :header => Vehicle.human_attribute_name(:maintenance_value)) do |value, relation, grid|
    relation.by_initial_maintenance_value(value[0]).by_final_maintenance_value(value[1])
  end

  column(:client_id, order: :client_id, if: :check_admin, header: Vehicle.human_attribute_name(:client_id) ) do |record, grid|
    if record.client
      record.client.fantasy_name
    end
  end

  column(:cost_center_id, order: :cost_center_id, if: :check_user, header: Vehicle.human_attribute_name(:cost_center_sub_unit) ) do |record, grid|
    record.getting_cost_center_unit_name
  end

  column(:board, order: :board, if: :check_user, header: Vehicle.human_attribute_name(:board) ) do |record, grid|
    record.board
  end

  column(:model, order: :model, if: :check_user, header: Vehicle.human_attribute_name(:model) ) do |record, grid|
    record.model
  end

  column(:year, order: :year, if: :check_user, header: Vehicle.human_attribute_name(:year) ) do |record, grid|
    record.year
  end

  column(:value_text, if: :check_user, header: Vehicle.human_attribute_name(:value_text) ) do |record, grid|
    record.value_text
  end

  column(:maintenance_value, if: :check_user, header: Vehicle.human_attribute_name(:maintenance_value_column) ) do |record, grid|
    CustomHelper.to_currency(record.get_maintenance_value)
  end

  column(:active, if: :check_user, html: true, order: :active, header: Vehicle.human_attribute_name(:active) ) do |record, grid|
    render "common_pages/column_yes_no", record: record.active
  end

  column(:active, if: :check_user, html: false, order: :active, header: Vehicle.human_attribute_name(:active) ) do |record, grid|
    CustomHelper.show_text_yes_no(record.active)
  end

  column(:order_services, if: :check_user, html: true, header: OrderService.model_name.human(count: 2) ) do |record, grid|
    render "vehicles/order_services_modal_trigger", record: record
  end

  column(:actions, if: :check_user, html: true, header: Vehicle.human_attribute_name(:actions) ) do |record, grid|
    render "datagrid_actions", record: record
  end

end
