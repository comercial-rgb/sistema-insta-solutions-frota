class OrientationManualsGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    OrientationManual.all
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

  filter(:profile_id, :enum, if: :check_admin, select: proc { Profile.to_orientation_manual.map {|c| [c.name, c.id] }}, header: OrientationManual.human_attribute_name(:profile_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_profile_id(value)
  end

  filter(:name, :string, if: :check_user, header: OrientationManual.human_attribute_name(:name)) do |value, relation, grid|
    relation.by_name(value)
  end

  filter(:description, :string, if: :check_user, header: OrientationManual.human_attribute_name(:description)) do |value, relation, grid|
    relation.by_description(value)
  end

end
