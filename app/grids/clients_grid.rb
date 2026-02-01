class ClientsGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    User.client
  end

  attr_accessor :current_user
  # grid.current_user para acessar o usuário
  # grid[:id] para acessar o filtro atual (no id, por exemplo)
  # grid[:created_at][0] para acessar o filtro atual quando for range true

  def check_user
    # return (!current_user.user?)
    return true
  end

  filter(:social_name, :string, if: :check_user, header: User.human_attribute_name(:social_name)) do |value, relation, grid|
    relation.by_social_name(value)
  end

  filter(:fantasy_name, :string, if: :check_user, header: User.human_attribute_name(:fantasy_name)) do |value, relation, grid|
    relation.by_fantasy_name(value)
  end

  filter(:_cnpj, :string, if: :check_user, header: User.human_attribute_name(:cnpj)) do |value, relation, grid|
    relation.by_cpf_cnpj(value)
  end

  filter(:email, :string, if: :check_user, header: User.human_attribute_name(:only_email_text)) do |value, relation, grid|
    relation.by_email(value)
  end

  filter(:state_id, :enum, if: :check_user, select: proc { State.order(:name).map {|c| [c.acronym, c.id] }}, header: User.human_attribute_name(:state_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_state_id_address(value)
  end

  filter(:city_id, :enum, if: :check_user, select: proc { City.order(:name).map {|c| [c.name, c.id] }}, header: User.human_attribute_name(:city_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_city_id_address(value)
  end

  filter(:is_blocked, :enum, if: :check_user, select: [[User.human_attribute_name(:active),0], [User.human_attribute_name(:inactive),1]], header: User.human_attribute_name(:only_status_text), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_is_blocked(value)
  end

  column(:social_name, order: :social_name, if: :check_user, header: User.human_attribute_name(:social_name) ) do |record, grid|
    record.social_name.to_s.force_encoding('UTF-8')
  end

  column(:fantasy_name, order: :fantasy_name, if: :check_user, header: User.human_attribute_name(:fantasy_name) ) do |record, grid|
    record.fantasy_name.to_s.force_encoding('UTF-8')
  end

  column(:state_city, order: :state_city, if: :check_user, header: User.human_attribute_name(:state_city) ) do |record, grid|
    record.get_state_city_by_address
  end

  column(:_cnpj, if: :check_user, header: User.human_attribute_name(:cnpj) ) do |record, grid|
    record.cnpj
  end

  column(:email, order: :email, if: :check_user, header: User.human_attribute_name(:only_email_text) ) do |record, grid|
    record.email
  end

  column(:is_blocked, if: :check_user, html: true, order: :is_blocked, header: User.human_attribute_name(:status) ) do |record, grid|
    render "user_status", record: record
  end

  column(:is_blocked, if: :check_user, html: false, order: :is_blocked, header: User.human_attribute_name(:only_status_text) ) do |record, grid|
    record.get_is_blocked?
  end

  column(:actions, if: :check_user, html: true, header: User.human_attribute_name(:actions) ) do |record, grid|
    render "datagrid_actions", record: record
  end

end
