class CommitmentsGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    Commitment.all
  end

  attr_accessor :current_user, :cost_centers, :contracts, :sub_units
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

  def get_cost_centers
    return cost_centers
  end

  def get_sub_units
    return sub_units
  end

  def get_contracts
    return contracts
  end

  filter(:client_id, :enum, if: :check_admin, select: proc { User.client.order(:fantasy_name).map {|c| [c.fantasy_name, c.id] }}, header: Commitment.human_attribute_name(:client_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_client_id(value)
  end

  filter(:cost_center_id, :enum, if: :check_user, select: :get_cost_centers, header: Commitment.human_attribute_name(:cost_center_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_cost_center_id(value)
  end

  filter(:sub_unit_id, :enum, if: :check_user, select: :get_sub_units, header: Commitment.human_attribute_name(:sub_unit_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_sub_unit_id(value)
  end

  filter(:contract_id, :enum, if: :check_user, select: :get_contracts, header: Commitment.human_attribute_name(:contract_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_contract_id(value)
  end

  filter(:commitment_number, :string, if: :check_user, header: Commitment.human_attribute_name(:commitment_number)) do |value, relation, grid|
    relation.by_commitment_number(value)
  end

  filter(:commitment_value, :integer, :range => true, if: :check_user, :header => Commitment.human_attribute_name(:commitment_value)) do |value, relation, grid|
    relation.by_initial_commitment_value(value[0]).by_final_commitment_value(value[1])
  end

  column(:client_id, if: :check_admin, order: :client_id, header: Commitment.human_attribute_name(:client_id) ) do |record, grid|
    if record.client
      record.client.fantasy_name
    end
  end

  column(:cost_center_id, if: :check_user, order: :cost_center_id, header: CostCenter.model_name.human(count: 2) ) do |record, grid|
    # Prioriza múltiplos centros de custo da nova tabela de relacionamento
    if record.cost_centers.any?
      record.cost_centers.map(&:get_text_name).join(', ')
    elsif record.cost_center.present?
      record.cost_center.get_text_name
    else
      '-'
    end
  end

  column(:sub_unit_id, if: :check_user, order: :sub_unit_id, header: Commitment.human_attribute_name(:sub_unit_id) ) do |record, grid|
    if record.sub_unit
      record.sub_unit.name
    end
  end

  column(:contract_id, if: :check_user, order: :contract_id, header: Commitment.human_attribute_name(:contract_id) ) do |record, grid|
    if record.contract
      record.contract.get_text_name
    end
  end

  column(:commitment_number, order: :commitment_number, if: :check_user, header: Commitment.human_attribute_name(:commitment_number) ) do |record, grid|
    record.commitment_number
  end

  column(:category_id, order: :category_id, if: :check_user, header: Commitment.human_attribute_name(:category_id) ) do |record, grid|
    record.category&.name || "Global"
  end

  column(:commitment_value, order: :commitment_value, if: :check_user, header: Commitment.human_attribute_name(:commitment_value) ) do |record, grid|
    CustomHelper.to_currency(record.commitment_value)
  end

  column(:already_consumed_value, if: :check_user, header: Commitment.human_attribute_name(:already_consumed_value) ) do |record, grid|
    CustomHelper.to_currency(Commitment.get_total_already_consumed_value(record))
  end

  column(:pendent_value, if: :check_user, header: Commitment.human_attribute_name(:pendent_value) ) do |record, grid|
    result = Commitment.getting_values_to_commitment(record)
    CustomHelper.to_currency(result[:pendent_value])
  end

  column(:active, if: :check_user, html: true, order: :active, header: Commitment.human_attribute_name(:active) ) do |record, grid|
    render "common_pages/column_yes_no", record: record.active
  end

  column(:active, if: :check_user, html: false, order: :active, header: Commitment.human_attribute_name(:active) ) do |record, grid|
    CustomHelper.show_text_yes_no(record.active)
  end

  column(:canceled_value, order: :canceled_value, html: true, if: :check_user, header: Commitment.human_attribute_name(:canceled_value) ) do |record, grid|
    render "show_canceled_value", record: record
  end

  column(:actions, if: :check_user, html: true, header: Commitment.human_attribute_name(:actions) ) do |record, grid|
    render "datagrid_actions", record: record
  end

end
