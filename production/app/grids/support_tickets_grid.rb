class SupportTicketsGrid

  include Datagrid

  scope do
    SupportTicket.all
  end

  attr_accessor :current_user

  def check_user
    return true
  end

  def check_admin
    return current_user.admin?
  end

  filter(:status, :enum, select: SupportTicket::STATUSES, header: "Status", include_blank: "Todos") do |value, relation, grid|
    relation.by_status(value)
  end

  filter(:ticket_type, :enum, select: SupportTicket::TICKET_TYPES, header: "Tipo", include_blank: "Todos") do |value, relation, grid|
    relation.by_ticket_type(value)
  end

  filter(:criticality, :enum, select: SupportTicket::CRITICALITIES, header: "Criticidade", include_blank: "Todos") do |value, relation, grid|
    relation.by_criticality(value)
  end

  filter(:title, :string, header: "Título") do |value, relation, grid|
    relation.by_title(value)
  end

  filter(:user_id, :enum, if: :check_admin, select: proc { User.where(profile_id: [Profile::ADMIN_ID, Profile::USER_ID, Profile::MANAGER_ID, Profile::ADDITIONAL_ID, Profile::CLIENTE_ID]).order(:name).map { |u| [u.name, u.id] } }, header: "Aberto por", include_blank: "Todos") do |value, relation, grid|
    relation.by_user_id(value)
  end

  filter(:created_at, :date, :range => true, header: "Data de abertura") do |value, relation, grid|
    relation.by_initial_date(value[0]).by_final_date(value[1])
  end

  column(:id, order: :id, header: "ID") do |record, grid|
    record.id
  end

  column(:title, order: :title, header: "Título") do |record, grid|
    record.title
  end

  column(:ticket_type, order: :ticket_type, header: "Tipo", html: true) do |record, grid|
    render "support_tickets/column_ticket_type", record: record
  end

  column(:ticket_type, order: :ticket_type, header: "Tipo", html: false) do |record, grid|
    record.ticket_type_name
  end

  column(:criticality, order: :criticality, header: "Criticidade", html: true) do |record, grid|
    render "support_tickets/column_criticality", record: record
  end

  column(:criticality, order: :criticality, header: "Criticidade", html: false) do |record, grid|
    record.criticality_name
  end

  column(:status, order: :status, header: "Status", html: true) do |record, grid|
    render "support_tickets/column_status", record: record
  end

  column(:status, order: :status, header: "Status", html: false) do |record, grid|
    record.status_name
  end

  column(:user_id, order: :user_id, header: "Aberto por") do |record, grid|
    record.user&.name || '-'
  end

  column(:created_at, order: :created_at, header: "Data de abertura") do |record, grid|
    record.created_at&.strftime("%d/%m/%Y %H:%M")
  end

  column(:resolved_at, order: :resolved_at, header: "Resolvido em") do |record, grid|
    record.resolved_at&.strftime("%d/%m/%Y %H:%M") || '-'
  end

  column(:actions, html: true, header: "Ações") do |record, grid|
    render "support_tickets/datagrid_actions", record: record
  end

end
