class ManagersGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    User.manager
  end

  attr_accessor :current_user
  # grid.current_user para acessar o usuário
  # grid[:id] para acessar o filtro atual (no id, por exemplo)
  # grid[:created_at][0] para acessar o filtro atual quando for range true

  def check_user
    # return (!current_user.user?)
    return true
  end

  filter(:name, :string, if: :check_user, header: User.human_attribute_name(:name)) do |value, relation, grid|
    relation.by_name(value)
  end

  filter(:email, :string, if: :check_user, header: User.human_attribute_name(:email)) do |value, relation, grid|
    relation.by_email(value)
  end

  filter(:_cpf, :string, if: :check_user, header: User.human_attribute_name(:cpf)) do |value, relation, grid|
    relation.by_cpf_cnpj(value)
  end

  filter(:registration, :string, if: :check_user, header: User.human_attribute_name(:registration)) do |value, relation, grid|
    relation.by_registration(value)
  end

  filter(:client_id, :enum, if: :check_user, select: proc { User.client.order(:fantasy_name).map {|c| [c.fantasy_name, c.id] }}, header: User.human_attribute_name(:client_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_client_id(value)
  end

  filter(:state_id, :enum, if: :check_user, select: proc { State.order(:name).map {|c| [c.acronym, c.id] }}, header: User.human_attribute_name(:state_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_state_id(value)
  end

  filter(:city_id, :enum, if: :check_user, select: proc { City.order(:name).map {|c| [c.name, c.id] }}, header: User.human_attribute_name(:city_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_city_id(value)
  end

  filter(:is_blocked, :enum, if: :check_user, select: [[User.human_attribute_name(:active),0], [User.human_attribute_name(:inactive),1]], header: User.human_attribute_name(:status), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_is_blocked(value)
  end

  column(:client_id, order: :client_id, if: :check_user, header: User.human_attribute_name(:client_id) ) do |record, grid|
    if record.client
      record.client.fantasy_name
    end
  end

  column(:name, order: :name, if: :check_user, header: User.human_attribute_name(:name) ) do |record, grid|
    record.get_name
  end

  column(:_cpf, order: :cpf, if: :check_user, header: User.human_attribute_name(:cpf) ) do |record, grid|
    record.get_document
  end

  column(:registration, order: :registration, if: :check_user, header: User.human_attribute_name(:registration) ) do |record, grid|
    record.registration
  end

  column(:email, order: :email, if: :check_user, header: User.human_attribute_name(:email) ) do |record, grid|
    record.email
  end

  column(:state_city, if: :check_user, header: User.human_attribute_name(:state_city) ) do |record, grid|
    record.get_state_city
  end

  column(:is_blocked, if: :check_user, html: true, order: :is_blocked, header: User.human_attribute_name(:status) ) do |record, grid|
    render "user_status", record: record
  end

  column(:is_blocked, if: :check_user, html: false, order: :is_blocked, header: User.human_attribute_name(:status) ) do |record, grid|
    record.get_is_blocked?
  end

  column(:actions, if: :check_user, html: true, header: User.human_attribute_name(:actions) ) do |record, grid|
    render "datagrid_actions", record: record
  end

end
