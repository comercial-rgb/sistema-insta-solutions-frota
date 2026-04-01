class UserEmailSetting < ApplicationRecord
  belongs_to :user

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :user_id, message: 'já cadastrado para este usuário' }

  scope :active, -> { where(active: true) }
  scope :by_sector, ->(sector) { where(sector: sector) if sector.present? }
  scope :for_os, -> { where(receive_os_notifications: true) }
  scope :for_invoices, -> { where(receive_invoice_notifications: true) }
  scope :for_payments, -> { where(receive_payment_notifications: true) }
  scope :for_approvals, -> { where(receive_approval_notifications: true) }
  scope :for_reports, -> { where(receive_report_notifications: true) }

  SECTORS = [
    'Financeiro',
    'Operacional',
    'Diretoria',
    'Administrativo',
    'Compras',
    'Frotas',
    'RH',
    'TI',
    'Outro'
  ].freeze

  NOTIFICATION_TYPES = {
    receive_os_notifications: 'Ordens de Serviço',
    receive_invoice_notifications: 'Faturas',
    receive_payment_notifications: 'Pagamentos',
    receive_approval_notifications: 'Aprovações',
    receive_report_notifications: 'Relatórios'
  }.freeze

  def notification_types_text
    types = []
    NOTIFICATION_TYPES.each do |attr, label|
      types << label if send(attr)
    end
    types.any? ? types.join(', ') : 'Nenhum'
  end
end
