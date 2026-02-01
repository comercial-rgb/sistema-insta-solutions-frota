class StatesGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    State.all
  end

  attr_accessor :current_user
  # grid.current_user para acessar o usuário

  def check_user
    # return (!current_user.user?)
    return true
  end

  filter(:name, :string, if: :check_user, header: State.human_attribute_name(:name)) do |value, relation, grid|
    relation.by_name(value)
  end

  filter(:country_id, :enum, if: :check_user, select: proc { Country.order(:name).map {|c| [c.name, c.id] }}, header: State.human_attribute_name(:country_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_country_id(value)
  end

  column(:name, if: :check_user, order: :name, header: State.human_attribute_name(:name) ) do |record, grid|
    record.name
  end

  column(:acronym, if: :check_user, order: :acronym, header: State.human_attribute_name(:acronym) ) do |record, grid|
    record.acronym
  end

  column(:country_id, if: :check_user, order: :country_id, header: State.human_attribute_name(:country_id) ) do |record, grid|
    if record.country
      record.country.name
    end
  end

  column(:actions, if: :check_user, html: true, header: State.human_attribute_name(:actions) ) do |record, grid|
    render "datagrid_actions", record: record
  end

end
