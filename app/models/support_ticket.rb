class SupportTicket < ApplicationRecord
  after_initialize :default_values

  # Tipos de chamado
  TICKET_TYPE_BUG = 0
  TICKET_TYPE_MELHORIA = 1
  TICKET_TYPE_SUPORTE = 2

  TICKET_TYPES = [
    ['Bug / Erro', TICKET_TYPE_BUG],
    ['Melhoria', TICKET_TYPE_MELHORIA],
    ['Suporte', TICKET_TYPE_SUPORTE]
  ].freeze

  # Criticidade
  CRITICALITY_BAIXA = 0
  CRITICALITY_MEDIA = 1
  CRITICALITY_ALTA = 2
  CRITICALITY_CRITICA = 3

  CRITICALITIES = [
    ['Baixa', CRITICALITY_BAIXA],
    ['Média', CRITICALITY_MEDIA],
    ['Alta', CRITICALITY_ALTA],
    ['Crítica', CRITICALITY_CRITICA]
  ].freeze

  # Status
  STATUS_ABERTO = 0
  STATUS_EM_ANDAMENTO = 1
  STATUS_RESOLVIDO = 2
  STATUS_FECHADO = 3

  STATUSES = [
    ['Aberto', STATUS_ABERTO],
    ['Em andamento', STATUS_EM_ANDAMENTO],
    ['Resolvido', STATUS_RESOLVIDO],
    ['Fechado', STATUS_FECHADO]
  ].freeze

  default_scope {
    includes(:user, :resolved_by_user)
    .order(created_at: :desc)
  }

  scope :by_status, lambda { |value| where("support_tickets.status = ?", value) if !value.nil? && value != "" }
  scope :by_ticket_type, lambda { |value| where("support_tickets.ticket_type = ?", value) if !value.nil? && value != "" }
  scope :by_criticality, lambda { |value| where("support_tickets.criticality = ?", value) if !value.nil? && value != "" }
  scope :by_user_id, lambda { |value| where("support_tickets.user_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_title, lambda { |value| where("LOWER(support_tickets.title) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  scope :by_initial_date, lambda { |value| where("support_tickets.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("support_tickets.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }
  scope :open_tickets, -> { where(status: [STATUS_ABERTO, STATUS_EM_ANDAMENTO]) }

  belongs_to :user
  belongs_to :resolved_by_user, class_name: 'User', foreign_key: 'resolved_by_id', optional: true

  has_many :support_ticket_messages, dependent: :destroy
  has_many :attachments, as: :ownertable, validate: false, dependent: :destroy
  accepts_nested_attributes_for :attachments, reject_if: :all_blank

  validates_presence_of :title, :description, :ticket_type, :criticality, :user_id

  def ticket_type_name
    TICKET_TYPES.find { |name, value| value == self.ticket_type }&.first || '-'
  end

  def criticality_name
    CRITICALITIES.find { |name, value| value == self.criticality }&.first || '-'
  end

  def status_name
    STATUSES.find { |name, value| value == self.status }&.first || '-'
  end

  def criticality_badge_class
    case self.criticality
    when CRITICALITY_BAIXA then 'bg-info'
    when CRITICALITY_MEDIA then 'bg-warning text-dark'
    when CRITICALITY_ALTA then 'bg-orange'
    when CRITICALITY_CRITICA then 'bg-danger'
    else 'bg-secondary'
    end
  end

  def status_badge_class
    case self.status
    when STATUS_ABERTO then 'bg-primary'
    when STATUS_EM_ANDAMENTO then 'bg-warning text-dark'
    when STATUS_RESOLVIDO then 'bg-success'
    when STATUS_FECHADO then 'bg-secondary'
    else 'bg-secondary'
    end
  end

  def ticket_type_badge_class
    case self.ticket_type
    when TICKET_TYPE_BUG then 'bg-danger'
    when TICKET_TYPE_MELHORIA then 'bg-info'
    when TICKET_TYPE_SUPORTE then 'bg-primary'
    else 'bg-secondary'
    end
  end

  def open?
    self.status == STATUS_ABERTO || self.status == STATUS_EM_ANDAMENTO
  end

  def resolved?
    self.status == STATUS_RESOLVIDO || self.status == STATUS_FECHADO
  end

  private

  def default_values
    self.status ||= STATUS_ABERTO
    self.ticket_type ||= TICKET_TYPE_BUG
    self.criticality ||= CRITICALITY_BAIXA
  end
end
