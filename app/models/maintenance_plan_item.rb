class MaintenancePlanItem < ApplicationRecord
  belongs_to :maintenance_plan
  belongs_to :client, class_name: 'User', optional: true

  has_many :maintenance_alerts, dependent: :destroy

  validates :name, presence: true
  validates :plan_type, inclusion: { in: %w[km days both] }
  validates :km_interval, numericality: { greater_than: 0 }, allow_nil: true
  validates :days_interval, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :by_client, ->(client_id) { where(client_id: client_id) if client_id.present? }
  scope :km_based, -> { where(plan_type: %w[km both]) }
  scope :days_based, -> { where(plan_type: %w[days both]) }

  PLAN_TYPES = %w[km days both].freeze
end
