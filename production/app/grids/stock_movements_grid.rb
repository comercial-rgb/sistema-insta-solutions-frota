class StockMovementsGrid

  include Datagrid

  scope do
    StockMovement.includes(:stock_item, :user, :order_service).order(created_at: :desc)
  end

  attr_accessor :current_user

  def check_user
    true
  end

  def check_admin
    current_user&.admin?
  end

  # Filters
  filter(:stock_item_name, :string, header: 'Peça') do |value, scope|
    scope.joins(:stock_item).where("stock_items.name LIKE ?", "%#{value}%")
  end

  filter(:movement_type, :enum, select: StockMovement.movement_types.map { |k, v| [I18n.t("activerecord.attributes.stock_movement.movement_types.#{k}"), v] },
    header: 'Tipo', include_blank: 'Todos') do |value, scope|
    scope.where(movement_type: value)
  end

  filter(:source, :enum, select: StockMovement.sources.map { |k, v| [I18n.t("activerecord.attributes.stock_movement.sources.#{k}"), v] },
    header: 'Origem', include_blank: 'Todas') do |value, scope|
    scope.where(source: value)
  end

  filter(:document_number, :string, header: 'Nº Documento') do |value, scope|
    scope.by_document_number(value)
  end

  filter(:created_at, :date, range: true, header: 'Data') do |value, scope|
    scope.by_initial_date(value[0]).by_final_date(value[1])
  end

  # Columns
  column(:stock_item, header: 'Peça', html: true) do |record|
    format(record.stock_item&.formatted_name) do |value|
      link_to(value, Rails.application.routes.url_helpers.stock_item_path(record.stock_item))
    end
  end

  column(:stock_item, header: 'Peça', html: false) do |record|
    record.stock_item&.formatted_name
  end

  column(:movement_type, header: 'Tipo', html: true) do |record|
    css = record.is_entry? ? 'bg-success' : 'bg-danger'
    format(record.movement_type) do
      "<span class='badge #{css}'>#{record.movement_type_label}</span>".html_safe
    end
  end

  column(:movement_type, header: 'Tipo', html: false) do |record|
    record.movement_type_label
  end

  column(:quantity, header: 'Quantidade') do |record|
    prefix = record.is_entry? ? '+' : '-'
    "#{prefix}#{record.quantity}"
  end

  column(:balance_after, header: 'Saldo Após') do |record|
    record.balance_after.to_s
  end

  column(:source, header: 'Origem') do |record|
    record.source_label
  end

  column(:document_number, header: 'Documento') do |record|
    record.document_number || '-'
  end

  column(:user, header: 'Usuário') do |record|
    record.user&.name
  end

  column(:reason, header: 'Motivo') do |record|
    record.reason.present? ? record.reason.truncate(50) : '-'
  end

  column(:created_at, order: :created_at, header: 'Data') do |record|
    record.created_at.strftime('%d/%m/%Y %H:%M')
  end

end
