class ServicesGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    Service.all.order(:name)
  end

  attr_accessor :current_user
  # grid.current_user para acessar o usuário

  def check_user
    return current_user.present?
  end

  def check_admin
    return current_user&.admin?
  end

  filter(:category_id, :enum, if: :check_user, select: proc { Category.by_category_type_id(CategoryType::SERVICOS_ID).order(:id).map {|c| [c.name, c.id] }}, header: Service.human_attribute_name(:category_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_category_id(value)
  end

  filter(:name, :string, if: :check_user, header: Service.human_attribute_name(:name)) do |value, relation, grid|
    relation.by_name(value)
  end

  column(:category_id, if: :check_user, order: :category_id, header: Service.human_attribute_name(:category_id) ) do |record, grid|
    if record.category
      record.category.name
    end
  end

  column(:name, if: :check_user, order: :name, header: Service.human_attribute_name(:name) ) do |record, grid|
    record.name
  end

  column(:actions, if: :check_user, html: true, header: Service.human_attribute_name(:actions) ) do |record, grid|
    render "datagrid_actions", record: record
  end

end
