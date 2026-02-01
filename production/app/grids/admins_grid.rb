class AdminsGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    User.admin.where.not(id: 1)
  end

  attr_accessor :current_user
  # grid.current_user para acessar o usuário

  def check_user
    # return (!current_user.user?)
    return true
  end

  filter(:name, :string, if: :check_user, header: User.human_attribute_name(:name)) do |value, relation, grid|
    relation.by_name(value)
  end

  # filter(:created_at, :date, :range => true, if: :check_user, :header => User.human_attribute_name(:created_at)) do |value, relation, grid|
  #   relation.by_initial_date(value[0]).by_final_date(value[1])
  # end

  filter(:is_blocked, :enum, if: :check_user, select: [[User.human_attribute_name(:active),0],[User.human_attribute_name(:inactive),1]], header: User.human_attribute_name(:status), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_is_blocked(value)
  end
  
  column(:name, order: :name, if: :check_user, header: User.human_attribute_name(:name) ) do |record, grid|
    record.name
  end

  column(:email, order: :email, if: :check_user, header: User.human_attribute_name(:email) ) do |record, grid|
    record.email
  end

  # column(:created_at, order: :created_at, if: :check_user, header: User.human_attribute_name(:created_at) ) do |record, grid|
  #   CustomHelper.get_text_date(record.created_at, 'datetime', :full)
  # end

  column(:is_blocked, html: true, if: :check_user, order: :is_blocked, header: User.human_attribute_name(:status) ) do |record, grid|
    render "user_status", record: record
  end

  column(:is_blocked, if: :check_user, html: false, order: :is_blocked, header: User.human_attribute_name(:status) ) do |record, grid|
    record.get_is_blocked?
  end
  
  column(:actions, html: true, if: :check_user, header: User.human_attribute_name(:actions) ) do |record, grid|
    render "datagrid_actions", record: record
  end

end
