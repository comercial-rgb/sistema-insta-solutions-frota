class ValidateUsersGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    User.waiting_validation
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

  filter(:profile_id, :enum, if: :check_user, select: proc { Profile.where.not(id: 1).map {|c| [c.name, c.id] }}, header: User.human_attribute_name(:profile_type), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_profile_id(value)
  end

  filter(:person_type_id, :enum, if: :check_user, select: proc { PersonType.order(:name).map {|c| [c.name, c.id] }}, header: User.human_attribute_name(:person_type_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_person_type_id(value)
  end

  filter(:name, :string, if: :check_user, header: User.human_attribute_name(:name)) do |value, relation, grid|
    relation.by_all_name(value)
  end

  filter(:_cpf_cnpj, :string, if: :check_user, header: User.human_attribute_name(:cpf_cnpj)) do |value, relation, grid|
    relation.by_cpf_cnpj(value)
  end

  filter(:created_at, :date, if: :check_user, :range => true, :header => User.human_attribute_name(:created_at)) do |value, relation, grid|
    relation.by_initial_date(value[0]).by_final_date(value[1])
  end

  column(:select_register, html: true, header: "#" ) do |record, grid|
    render "common_pages/datagrid/select_register", record: record, current_model: "user"
  end

  column(:created_at, if: :check_user, order: :created_at, header: User.human_attribute_name(:created_at) ) do |record, grid|
    CustomHelper.get_text_date(record.created_at, 'datetime', :full)
  end

  column(:profile_id, order: :profile_id, if: :check_admin, header: User.human_attribute_name(:profile_type) ) do |record, grid|
    if record.profile
      record.profile.name
    end
  end

  column(:person_type_id, order: :person_type_id, if: :check_admin, header: User.human_attribute_name(:person_type_id) ) do |record, grid|
    if record.person_type
      record.person_type.name
    end
  end

  column(:name, order: :name, if: :check_user, header: User.human_attribute_name(:name) ) do |record, grid|
    record.get_name
  end

  column(:_cpf_cnpj, order: :cpf_cnpj, if: :check_user, header: User.human_attribute_name(:cpf_cnpj) ) do |record, grid|
    record.get_document
  end

  column(:email, order: :email, if: :check_user, header: User.human_attribute_name(:email) ) do |record, grid|
    record.email
  end

  column(:phone, order: :phone, if: :check_user, header: User.human_attribute_name(:phone) ) do |record, grid|
    record.phone
  end

  column(:user_status_id, if: :check_user, html: true, order: :user_status_id, header: User.human_attribute_name(:user_status_id) ) do |record, grid|
    render "user_status_to_validate", record: record
  end

end
