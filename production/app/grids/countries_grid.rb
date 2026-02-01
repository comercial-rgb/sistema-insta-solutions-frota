class CountriesGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    Country.all.order(:name)
  end

  attr_accessor :current_user
  # grid.current_user para acessar o usuário

  def check_user
    # return (!current_user.user?)
    return true
  end

  filter(:name, :string, if: :check_user, header: Country.human_attribute_name(:name)) do |value, relation, grid|
    relation.by_name(value)
  end

  column(:name, if: :check_user, order: :name, header: Country.human_attribute_name(:name) ) do |record, grid|
    record.name
  end

  column(:actions, if: :check_user, html: true, header: Country.human_attribute_name(:actions) ) do |record, grid|
    render "datagrid_actions", record: record
  end

end
