class ProvidersGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    User.provider
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

  filter(:name, :string, if: :check_user, header: User.human_attribute_name(:name)) do |value, relation, grid|
    relation.by_name(value)
  end

  filter(:fantasy_name, :string, if: :check_user, header: User.human_attribute_name(:fantasy_name)) do |value, relation, grid|
    relation.by_fantasy_name(value)
  end

  filter(:cpf_cnpj, :string, if: :check_user, header: User.human_attribute_name(:cpf_cnpj)) do |value, relation, grid|
    relation.by_cpf_cnpj(value)
  end

  filter(:email, :string, if: :check_admin, header: User.human_attribute_name(:only_email_text)) do |value, relation, grid|
    relation.by_email(value)
  end

  filter(:provider_service_type_id, :enum, if: :check_user, select: proc { ProviderServiceType.order(:name).map {|c| [c.name, c.id] }}, header: User.human_attribute_name(:provider_service_type_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_provider_service_type_id(value)
  end

  filter(:state_id, :enum, if: :check_user, select: proc { State.order(:name).map {|c| [c.acronym, c.id] }}, header: User.human_attribute_name(:state_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_state_id_address(value)
  end

  filter(:city_id, :enum, if: :check_user, select: proc { City.order(:name).map {|c| [c.name, c.id] }}, header: User.human_attribute_name(:city_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_city_id_address(value)
  end

  filter(:is_blocked, :enum, if: :check_admin, select: [[User.human_attribute_name(:active),0], [User.human_attribute_name(:inactive),1]], header: User.human_attribute_name(:status), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_is_blocked(value)
  end

  column(:name, order: :name, if: :check_user, header: User.human_attribute_name(:name) ) do |record, grid|
    record.name
  end

  column(:fantasy_name, order: :fantasy_name, if: :check_user, header: User.human_attribute_name(:fantasy_name) ) do |record, grid|
    record.fantasy_name
  end

  column(:address, if: :check_user, header: Address.model_name.human ) do |record, grid|
    record.address&.get_address_value
  end

  column(:_cpf_cnpj, if: :check_user, header: User.human_attribute_name(:cpf_cnpj) ) do |record, grid|
    record.get_document
  end

  column(:email, order: :email, if: :check_user, header: User.human_attribute_name(:only_email_text) ) do |record, grid|
    record.email
  end

  column(:_phone, order: :phone, if: :check_user, header: User.human_attribute_name(:phone) ) do |record, grid|
    record.phone
  end

  # column(:created_at, if: :check_user, order: :created_at, header: User.human_attribute_name(:created_at) ) do |record, grid|
  #   CustomHelper.get_text_date(record.created_at, 'datetime', :full)
  # end

  column(:is_blocked, if: :check_admin, html: true, order: :is_blocked, header: User.human_attribute_name(:status) ) do |record, grid|
    render "user_status", record: record
  end

  column(:is_blocked, if: :check_admin, html: false, order: :is_blocked, header: User.human_attribute_name(:status) ) do |record, grid|
    record.get_is_blocked?
  end

  column(:provider_service_types, if: :check_user, html: false, header: User.human_attribute_name(:provider_service_types) ) do |record, grid|
    record.provider_service_types.map(&:name).join(", ")
  end

  column(:actions, if: :check_admin, html: true, header: User.human_attribute_name(:actions) ) do |record, grid|
    render "datagrid_actions", record: record
  end

end
