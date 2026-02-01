class NotificationsGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    Notification.all
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

  def check_not_admin
    return (!current_user.admin?)
  end

  filter(:title, :string, if: :check_user, header: Notification.human_attribute_name(:title)) do |value, relation, grid|
    relation.by_title(value)
  end

  filter(:profile_id, :enum, if: :check_admin, select: proc { Profile.to_notification.order(:name).map {|c| [c.name, c.id] }}, header: Notification.human_attribute_name(:profile_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_profile_id(value)
  end

  filter(:created_at, :date, :range => true, if: :check_user, :header => Notification.human_attribute_name(:created_at)) do |value, relation, grid|
    relation.by_initial_date(value[0]).by_final_date(value[1])
  end

  column(:profile_id, order: :profile_id, if: :check_admin, header: Notification.human_attribute_name(:profile_id) ) do |record, grid|
    record.getting_profile_text
  end

  column(:users, html: true, if: :check_admin, header: Notification.human_attribute_name(:users) ) do |record, grid|
    render "show_users", record: record
  end

  column(:users, html: false, if: :check_admin, header: Notification.human_attribute_name(:users) ) do |record, grid|
    record.get_users
  end

  column(:title, order: :title, if: :check_user, header: Notification.human_attribute_name(:title) ) do |record, grid|
    record.title
  end

  column(:message, order: :message, html: true, if: :check_user, header: Notification.human_attribute_name(:message) ) do |record, grid|
    render "complete_message", record: record
  end

  column(:message, order: :message, html: false, if: :check_user, header: Notification.human_attribute_name(:message) ) do |record, grid|
    record.message
  end

  column(:created_at, if: :check_user, order: :created_at, header: Notification.human_attribute_name(:created_at) ) do |record, grid|
    CustomHelper.get_text_date(record.created_at, 'datetime', :full)
  end

  column(:manage_read, if: :check_not_admin, html: true, header: Notification.human_attribute_name(:manage_read) ) do |record, grid|
    render "manage_read", record: record
  end

  column(:actions, if: :check_admin, html: true, header: Notification.human_attribute_name(:actions) ) do |record, grid|
    render "datagrid_actions", record: record
  end

end
