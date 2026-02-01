class CitiesGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    City.all
  end

  attr_accessor :current_user
  # grid.current_user para acessar o usuário

  def check_user
    # return (!current_user.user?)
    return true
  end

  filter(:name, :string, if: :check_user, header: City.human_attribute_name(:name)) do |value, relation, grid|
    relation.by_name(value)
  end

  filter(:country_id, :enum, if: :check_user, select: proc { Country.order(:name).map {|c| [c.name, c.id] }}, header: City.human_attribute_name(:country_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_country_id(value)
  end

  filter(:state_id, :enum, if: :check_user, select: proc { State.order(:name).map {|c| [c.name, c.id] }}, header: City.human_attribute_name(:state_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_state_id(value)
  end

  column(:name, if: :check_user, order: :name, header: City.human_attribute_name(:name) ) do |record, grid|
    record.name
  end

  column(:country_id, if: :check_user, order: :country_id, header: City.human_attribute_name(:country_id) ) do |record, grid|
    if record.country
      record.country.name
    end
  end

  column(:state_id, if: :check_user, order: :state_id, header: City.human_attribute_name(:state_id) ) do |record, grid|
    if record.state
      record.state.name
    end
  end

  column(:actions, if: :check_user, html: true, header: City.human_attribute_name(:actions) ) do |record, grid|
    render "datagrid_actions", record: record
  end

end
