class Anomaly < ApplicationRecord
  belongs_to :vehicle
  belongs_to :user
  belongs_to :client, class_name: 'User', optional: true
  belongs_to :cost_center, optional: true
  belongs_to :resolved_by, class_name: 'User', optional: true

  has_many_attached :photos
  validates :photos, safe_file: { profile: :image }, if: -> { photos.attached? }

  validates :title, presence: true
  validates :severity, inclusion: { in: %w[low medium high critical] }
  validates :status, inclusion: { in: %w[open in_progress resolved closed] }

  scope :by_client, ->(client_id) { where(client_id: client_id) if client_id.present? }
  scope :by_vehicle, ->(vehicle_id) { where(vehicle_id: vehicle_id) if vehicle_id.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_severity, ->(severity) { where(severity: severity) if severity.present? }
  scope :open_anomalies, -> { where(status: %w[open in_progress]) }
  scope :recent, -> { order(created_at: :desc) }

  SEVERITIES = %w[low medium high critical].freeze
  STATUSES = %w[open in_progress resolved closed].freeze
  CATEGORIES = %w[mecanica eletrica pneus carroceria freios suspensao motor transmissao ar_condicionado outros].freeze
end
