class MaintenancePlansGrid

  include Datagrid

  scope do
    MaintenancePlan.all
  end

  attr_accessor :current_user

  def check_user
    return true
  end

  def check_admin
    return current_user.admin?
  end

  filter(:client_id, :enum, if: :check_admin, select: proc { User.client.order(:fantasy_name).map { |c| [c.fantasy_name, c.id] } }, header: "Cliente", include_blank: I18n.t('model.select_option')) do |value, relation, grid|
    relation.by_client(value)
  end

  filter(:name, :string, if: :check_user, header: "Nome do Plano") do |value, relation, grid|
    relation.where("maintenance_plans.name LIKE ?", "%#{value}%")
  end

  filter(:active, :enum, if: :check_user, select: CustomHelper.return_select_options_yes_no, header: "Ativo", include_blank: I18n.t('model.select_option')) do |value, relation, grid|
    relation.where(active: value == "true" || value == "1")
  end

  filter(:created_at, :date, range: true, if: :check_user, header: "Criado em") do |value, relation, grid|
    relation.by_initial_date(value[0]).by_final_date(value[1])
  end

  column(:client_id, order: :client_id, if: :check_admin, header: "Cliente") do |record, grid|
    record.client&.fantasy_name
  end

  column(:name, order: :name, if: :check_user, header: "Nome do Plano") do |record, grid|
    record.name
  end

  column(:description, if: :check_user, header: "Descrição") do |record, grid|
    record.description.to_s.truncate(50)
  end

  column(:items_count, if: :check_user, header: "Itens") do |record, grid|
    record.item_count
  end

  column(:vehicles_count, if: :check_user, header: "Veículos") do |record, grid|
    record.vehicle_count
  end

  column(:active, if: :check_user, html: true, order: :active, header: "Ativo") do |record, grid|
    render "common_pages/column_yes_no", record: record.active
  end

  column(:active, if: :check_user, html: false, order: :active, header: "Ativo") do |record, grid|
    CustomHelper.show_text_yes_no(record.active)
  end

  column(:created_at, order: :created_at, if: :check_user, header: "Criado em") do |record, grid|
    record.created_at&.strftime("%d/%m/%Y")
  end

  column(:actions, if: :check_user, html: true, header: "Ações") do |record, grid|
    render "datagrid_actions", record: record
  end

end
