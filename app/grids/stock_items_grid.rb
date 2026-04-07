class StockItemsGrid

  include Datagrid

  scope do
    StockItem.includes(:cost_center, :sub_unit, :category, :created_by).order(updated_at: :desc)
  end

  attr_accessor :current_user

  def check_user
    true
  end

  def check_admin
    current_user&.admin?
  end

  def check_not_admin
    !current_user&.admin?
  end

  # Filters
  filter(:client_id, :enum, if: :check_admin, select: -> { User.where(profile_id: Profile::CLIENT_ID).order(:name).map { |u| [u.name, u.id] } },
    header: 'Cliente', include_blank: 'Todos') do |value, scope|
    scope.by_client_id(value)
  end

  filter(:cost_center_id, :enum, if: :check_user, select: -> { CostCenter.order(:name).map { |cc| [cc.name, cc.id] } },
    header: 'Centro de Custo', include_blank: 'Todos') do |value, scope|
    scope.by_cost_center_id(value)
  end

  filter(:sub_unit_id, :enum, if: :check_user, select: -> { SubUnit.order(:name).map { |su| [su.name, su.id] } },
    header: 'Subunidade', include_blank: 'Todos') do |value, scope|
    scope.by_sub_unit_id(value)
  end

  filter(:name, :string, if: :check_user, header: 'Nome da Peça') do |value, scope|
    scope.by_name(value)
  end

  filter(:code, :string, if: :check_user, header: 'Código') do |value, scope|
    scope.by_code(value)
  end

  filter(:brand, :string, if: :check_user, header: 'Marca') do |value, scope|
    scope.by_brand(value)
  end

  filter(:part_number, :string, if: :check_user, header: 'Part Number') do |value, scope|
    scope.by_part_number(value)
  end

  filter(:status, :enum, if: :check_user, select: StockItem.statuses.map { |k, v| [I18n.t("activerecord.attributes.stock_item.statuses.#{k}"), v] },
    header: 'Status', include_blank: 'Todos') do |value, scope|
    scope.where(status: value)
  end

  # Columns
  column(:name, order: :name, html: true, header: 'Peça') do |record|
    format(record.formatted_name) do |value|
      link_to(value, Rails.application.routes.url_helpers.stock_item_path(record))
    end
  end

  column(:name, order: :name, html: false, header: 'Peça') do |record|
    record.formatted_name
  end

  column(:cost_center, order: 'cost_centers.name', header: 'Centro de Custo') do |record|
    record.cost_center&.name
  end

  column(:sub_unit, order: 'sub_units.name', header: 'Subunidade') do |record|
    record.sub_unit&.name || '-'
  end

  column(:quantity, order: :quantity, header: 'Qtd') do |record|
    "#{record.quantity} #{record.unit_measure}"
  end

  column(:minimum_quantity, order: :minimum_quantity, header: 'Qtd Mín') do |record|
    record.minimum_quantity > 0 ? "#{record.minimum_quantity} #{record.unit_measure}" : '-'
  end

  column(:unit_price, order: :unit_price, header: 'Preço Unit.') do |record|
    ActionController::Base.helpers.number_to_currency(record.unit_price, unit: 'R$', separator: ',', delimiter: '.')
  end

  column(:total_value, header: 'Valor Total') do |record|
    ActionController::Base.helpers.number_to_currency(record.total_value, unit: 'R$', separator: ',', delimiter: '.')
  end

  column(:status, header: 'Status', html: true) do |record|
    status_class = case record.status
                   when 'active' then 'bg-success'
                   when 'inactive' then 'bg-secondary'
                   when 'below_minimum' then 'bg-warning text-dark'
                   end
    format(record.status) do
      "<span class='badge #{status_class}'>#{I18n.t("activerecord.attributes.stock_item.statuses.#{record.status}")}</span>".html_safe
    end
  end

  column(:status, header: 'Status', html: false) do |record|
    I18n.t("activerecord.attributes.stock_item.statuses.#{record.status}")
  end

  column(:created_by, header: 'Incluído por') do |record|
    record.created_by&.name
  end

  column(:updated_at, order: :updated_at, header: 'Atualizado em') do |record|
    record.updated_at.strftime('%d/%m/%Y %H:%M')
  end

end
