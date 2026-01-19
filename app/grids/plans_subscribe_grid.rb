class PlansSubscribeGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    Plan.active
  end

  attr_accessor :current_user
  # grid.current_user para acessar o usuário

  def check_user
    # return (!current_user.user?)
    return true
  end

  # filter(:name, :string, if: :check_user, header: Plan.human_attribute_name(:name)) do |value, relation, grid|
  #   relation.by_name(value)
  # end

  # filter(:plan_periodicity_id, :enum, if: :check_user, select: proc { PlanPeriodicity.order(:name).map {|c| [c.name, c.id] }}, header: Plan.human_attribute_name(:plan_periodicity_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
  #   relation.by_plan_periodicity_id(value)
  # end

  # filter(:category_id, :enum, if: :check_user, select: proc { Category.by_category_type_id(CategoryType::PLANOS_ID).order(:name).map {|c| [c.name, c.id] }}, header: Plan.human_attribute_name(:category_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
  #   relation.by_category_id(value)
  # end

  # filter(:sub_category_id, :enum, if: :check_user, select: proc { SubCategory.order(:name).map {|c| [c.name, c.id] }}, header: Plan.human_attribute_name(:sub_category_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
  #   relation.by_sub_category_id(value)
  # end

  # filter(:active, :enum, if: :check_user, select: [[CustomHelper.show_text_yes_no(true),1], [CustomHelper.show_text_yes_no(false),0]], header: Plan.human_attribute_name(:active), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
  #   relation.by_active(value)
  # end

  # column(:image, if: :check_user, html: true, header: Plan.human_attribute_name(:image) ) do |record, grid|
  #   render "common_pages/show_image", record: record.image, resize_to_limit: [100,100], alt: ""
  # end

  # column(:name, if: :check_user, order: :name, header: Plan.human_attribute_name(:name) ) do |record, grid|
  #   record.name
  # end

  # column(:monthly_price, if: :check_user, order: :monthly_price, header: Plan.human_attribute_name(:monthly_price) ) do |record, grid|
  #   CustomHelper.to_currency(record.get_price_by_periodicity(PlanPeriodicity::MENSAL_ID))
  # end

  # column(:annual_price, if: :check_user, order: :annual_price, header: Plan.human_attribute_name(:annual_price) ) do |record, grid|
  #   CustomHelper.to_currency(record.get_price_by_periodicity(PlanPeriodicity::ANUAL_ID))
  # end

  # column(:category_id, if: :check_user, order: :category_id, header: Plan.human_attribute_name(:category_id) ) do |record, grid|
  #   if record.category
  #     record.category.name
  #   end
  # end

  # column(:sub_category_id, if: :check_user, order: :sub_category_id, header: Plan.human_attribute_name(:sub_category_id) ) do |record, grid|
  #   if record.sub_category
  #     record.sub_category.name
  #   end
  # end

  # column(:active, if: :check_user, html: true, order: :active, header: Plan.human_attribute_name(:active) ) do |record, grid|
  #   render "common_pages/column_yes_no", record: record.active
  # end

  # column(:active, if: :check_user, html: false, order: :active, header: Plan.human_attribute_name(:active) ) do |record, grid|
  #   CustomHelper.show_text_yes_no(record.active)
  # end
  
  # column(:actions, if: :check_user, html: true, header: Plan.human_attribute_name(:actions) ) do |record, grid|
  #   render "datagrid_actions", record: record
  # end

end
