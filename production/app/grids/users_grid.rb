class UsersGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    User.user
  end

  attr_accessor :current_user
  # grid.current_user para acessar o usuário
  # grid[:id] para acessar o filtro atual (no id, por exemplo)
  # grid[:created_at][0] para acessar o filtro atual quando for range true

  def check_user
    # return (!current_user.user?)
    return true
  end

  filter(:id, :string, if: :check_user, header: User.human_attribute_name(:id)) do |value, relation, grid|
    relation.by_id(value)
  end

  filter(:name, :string, if: :check_user, header: User.human_attribute_name(:name)) do |value, relation, grid|
    relation.by_name(value)
  end

  filter(:current_plan_id, :enum, if: false, select: proc { DataPlanPeriodicity.to_set_manually.map {|c| [c.get_title_complete, c.id] }}, header: User.human_attribute_name(:current_plan_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    if value.to_i == 2
      # Plano gratuito
      relation.by_current_plans_id([1,2])
    else
      relation.by_current_plan_id(value)
    end
  end

  filter(:manually_plan_id, :enum, if: false, select: proc { Plan.to_set_manually.map {|c| [c.name, c.id] }}, header: User.human_attribute_name(:manually_plan_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_manually_plan_id(value)
  end

  # filter(:person_type_id, :enum, if: :check_user, select: proc { PersonType.order(:name).map {|c| [c.name, c.id] }}, header: User.human_attribute_name(:person_type_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
  #   relation.by_person_type_id(value)
  # end

  # filter(:cpf_cnpj, :string, if: :check_user, header: User.human_attribute_name(:cpf_cnpj)) do |value, relation, grid|
  #   relation.by_cpf_cnpj(value)
  # end

  # filter(:created_at, :date, if: :check_user, :range => true, :header => User.human_attribute_name(:created_at)) do |value, relation, grid|
  #   relation.by_initial_date(value[0]).by_final_date(value[1])
  # end

  filter(:is_blocked, :enum, if: :check_user, select: [[User.human_attribute_name(:active),0], [User.human_attribute_name(:inactive),1]], header: User.human_attribute_name(:status), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_is_blocked(value)
  end

  filter(:user_status_id, :enum, if: :check_user, select: proc { UserStatus.order(:id).map {|c| [c.name, c.id] }}, header: User.human_attribute_name(:user_status_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_user_status_id(value)
  end

  column(:id, order: :id, if: :check_user, header: User.human_attribute_name(:id) ) do |record, grid|
    record.id
  end

  column(:current_plan_id, order: :current_plan_id, if: false, header: User.human_attribute_name(:current_plan_id) ) do |record, grid|
    if record.current_plan && record.current_plan.plan
      record.current_plan.get_title_complete
    end
  end

  column(:manually_plan_id, order: :manually_plan_id, if: false, header: User.human_attribute_name(:manually_plan_id) ) do |record, grid|
    if record.manually_plan
      record.manually_plan.get_text_name
    end
  end
  
  column(:name, order: :name, if: :check_user, header: User.human_attribute_name(:name) ) do |record, grid|
    record.get_name
  end

  column(:email, order: :email, if: :check_user, header: User.human_attribute_name(:email) ) do |record, grid|
    record.email
  end

  # column(:_cpf_cnpj, if: :check_user, header: User.human_attribute_name(:cpf_cnpj) ) do |record, grid|
  #   record.get_document
  # end

  # column(:created_at, if: :check_user, order: :created_at, header: User.human_attribute_name(:created_at) ) do |record, grid|
  #   CustomHelper.get_text_date(record.created_at, 'datetime', :full)
  # end

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
