class SiteContactsGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    SiteContact.all.order(created_at: :desc)
  end

  attr_accessor :current_user
  # grid.current_user para acessar o usuário

  def check_user
    # return (!current_user.user?)
    return true
  end

  filter(:id, :string, if: :check_user, header: SiteContact.human_attribute_name(:id)) do |value, relation, grid|
    relation.by_id(value)
  end

  filter(:site_contact_subject_id, :enum, if: :check_user, select: proc { SiteContactSubject.order(:name).map {|c| [c.name, c.id] }}, header: SiteContact.human_attribute_name(:site_contact_subject_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_site_contact_subject_id(value)
  end

  filter(:name, :string, if: :check_user, header: SiteContact.human_attribute_name(:name)) do |value, relation, grid|
    relation.by_name(value)
  end

  filter(:email, :string, if: :check_user, header: SiteContact.human_attribute_name(:email)) do |value, relation, grid|
    relation.by_email(value)
  end

  filter(:created_at, :date, if: :check_user, :range => true, :header => SiteContact.human_attribute_name(:created_at)) do |value, relation, grid|
    relation.by_initial_date(value[0]).by_final_date(value[1])
  end

  column(:id, order: :id, if: :check_user, header: SiteContact.human_attribute_name(:id) ) do |record, grid|
    record.id
  end
  
  column(:site_contact_subject_id, if: :check_user, order: :site_contact_subject_id, header: SiteContact.human_attribute_name(:site_contact_subject_id) ) do |record, grid|
    if record.site_contact_subject
      record.site_contact_subject.name
    end
  end

  column(:name, order: :name, if: :check_user, header: SiteContact.human_attribute_name(:name) ) do |record, grid|
    record.name
  end

  column(:email, order: :email, if: :check_user, header: SiteContact.human_attribute_name(:email) ) do |record, grid|
    record.email
  end

  column(:_phone, order: :phone, if: :check_user, header: SiteContact.human_attribute_name(:phone) ) do |record, grid|
    record.phone
  end

  column(:message, order: :message, if: :check_user, header: SiteContact.human_attribute_name(:message) ) do |record, grid|
    record.message
  end

  column(:created_at, if: :check_user, order: :created_at, header: SiteContact.human_attribute_name(:created_at) ) do |record, grid|
    CustomHelper.get_text_date(record.created_at, 'datetime', :full)
  end

  column(:actions, if: :check_user, html: true, header: SiteContact.human_attribute_name(:actions) ) do |record, grid|
    render "datagrid_actions", record: record
  end

end
