class DriversGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    User.driver
  end

  attr_accessor :current_user

  def check_user
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

  filter(:client_id, :enum, if: :check_user, select: proc { User.client.order(:fantasy_name).map {|c| [c.fantasy_name, c.id] } }, header: User.human_attribute_name(:client_id), include_blank: I18n.t('model.select_option')) do |value, relation, grid|
    relation.by_client_id(value)
  end

  filter(:cnh_category, :string, if: :check_user, header: 'Categoria CNH') do |value, relation, grid|
    relation.where("LOWER(users.cnh_category) LIKE ?", "%#{value.downcase}%")
  end

  column(:name, header: User.human_attribute_name(:name), order: "users.name", mandatory: true)
  column(:email, header: User.human_attribute_name(:email))
  column(:cpf, header: User.human_attribute_name(:cpf))
  column(:cnh_number, header: 'CNH')
  column(:cnh_category, header: 'Categoria')
  column(:cnh_expiration, header: 'Vencimento CNH') do |record|
    record.cnh_expiration&.strftime('%d/%m/%Y')
  end
  column(:client, header: User.human_attribute_name(:client_id)) do |record|
    record.client&.fantasy_name || record.client&.name
  end
  column(:is_blocked, header: User.human_attribute_name(:active)) do |record|
    record.is_blocked ? I18n.t('model.blocked') : I18n.t('model.active')
  end
  column(:actions, header: '', html: true, mandatory: true) do |record|
    render 'users/datagrid_actions', user: record
  end

end
