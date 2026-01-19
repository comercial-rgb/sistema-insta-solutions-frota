class CostCentersGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    CostCenter.all
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

  filter(:client_id, :enum, if: :check_admin, select: proc { User.client.order(:fantasy_name).map {|c| [c.fantasy_name, c.id] }}, header: CostCenter.human_attribute_name(:client_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_client_id(value)
  end

  filter(:name, :string, if: :check_user, header: CostCenter.human_attribute_name(:name)) do |value, relation, grid|
    relation.by_name(value)
  end

  column(:client_id, order: :client_id, if: :check_admin, header: CostCenter.human_attribute_name(:client_id) ) do |record, grid|
    if record.client
      record.client.fantasy_name
    end
  end

  column(:name, order: :name, if: :check_user, header: CostCenter.human_attribute_name(:name) ) do |record, grid|
    record.name
  end

  column(:budget_value, if: :check_user, header: CostCenter.human_attribute_name(:budget_value) ) do |record, grid|
    CustomHelper.to_currency(CostCenter.sum_budget_value(record))
  end

  column(:already_consumed_value, if: :check_user, header: CostCenter.human_attribute_name(:already_consumed_value) ) do |record, grid|
    CustomHelper.to_currency(CostCenter.get_total_already_consumed_value(record))
  end

  column(:pendent_value, if: :check_user, header: CostCenter.human_attribute_name(:pendent_value) ) do |record, grid|
    result = CostCenter.getting_values_to_cost_centers(record)
    CustomHelper.to_currency(result[:pendent_value])
  end

  column(:budget_type_id, order: :budget_type_id, if: :check_user, header: CostCenter.human_attribute_name(:budget_type_id) ) do |record, grid|
    if record.budget_type
      record.budget_type.name
    end
  end

  column(:sub_units, if: :check_user, html: true, header: CostCenter.human_attribute_name(:sub_units) ) do |record, grid|
    render "show_sub_units", record: record
  end

  column(:actions, if: :check_user, html: true, header: CostCenter.human_attribute_name(:actions) ) do |record, grid|
    render "datagrid_actions", record: record
  end

end
