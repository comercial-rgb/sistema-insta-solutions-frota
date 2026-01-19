class AddressesGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    Address.all
  end

  attr_accessor :current_user, :ownertable_type, :address_area_id, :ownertable_id, :page_title
  # grid.current_user para acessar o usuário

  def check_user
    # return (!current_user.user?)
    return true
  end

  filter(:name, :string, if: :check_user, header: Address.human_attribute_name(:name)) do |value, relation, grid|
    relation.by_name(value)
  end

end
