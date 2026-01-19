class ContractsGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    Contract.all
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

  filter(:client_id, :enum, if: :check_admin, select: proc { User.client.order(:fantasy_name).map {|c| [c.fantasy_name, c.id] }}, header: Contract.human_attribute_name(:client_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_client_id(value)
  end

  filter(:name, :string, if: :check_user, header: Contract.human_attribute_name(:name)) do |value, relation, grid|
    relation.by_name(value)
  end

  filter(:number, :string, if: :check_user, header: Contract.human_attribute_name(:number)) do |value, relation, grid|
    relation.by_number(value)
  end

  filter(:active, :enum, if: :check_user, select: CustomHelper.return_select_options_yes_no, header: Contract.human_attribute_name(:active), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_active(value)
  end

  column(:client_id, order: :client_id, if: :check_admin, header: Contract.human_attribute_name(:client_id) ) do |record, grid|
    if record.client
      record.client.fantasy_name
    end
  end

  column(:name, order: :name, if: :check_user, header: Contract.human_attribute_name(:name) ) do |record, grid|
    record.name
  end

  column(:number, order: :number, if: :check_user, header: Contract.human_attribute_name(:number) ) do |record, grid|
    record.number
  end

  column(:total_value, if: :check_user, order: :total_value, header: Contract.human_attribute_name(:total_value) ) do |record, grid|
    CustomHelper.to_currency(record.get_total_value)
  end

  column(:addendum_contracts, if: :check_user, html: true, header: Contract.human_attribute_name(:addendum_contracts) ) do |record, grid|
    render "show_addendum_contracts", record: record
  end

  column(:commitments, if: :check_user, html: true, header: Commitment.model_name.human(count: 2) ) do |record, grid|
    render "show_commitments", record: record
  end

  column(:active, if: :check_user, html: true, order: :active, header: Contract.human_attribute_name(:active) ) do |record, grid|
    render "common_pages/column_yes_no", record: record.active
  end

  column(:active, if: :check_user, html: false, order: :active, header: Contract.human_attribute_name(:active) ) do |record, grid|
    CustomHelper.show_text_yes_no(record.active)
  end

  column(:actions, if: :check_user, html: true, header: Contract.human_attribute_name(:actions) ) do |record, grid|
    render "datagrid_actions", record: record
  end

end
