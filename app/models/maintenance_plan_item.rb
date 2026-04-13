class MaintenancePlanItem < ApplicationRecord
  belongs_to :maintenance_plan
  belongs_to :client, class_name: 'User', optional: true

  has_many :maintenance_alerts, dependent: :destroy
  has_many :maintenance_plan_item_services, dependent: :destroy
  has_many :services, through: :maintenance_plan_item_services

  accepts_nested_attributes_for :maintenance_plan_item_services,
    reject_if: proc { |attrs| attrs[:service_id].blank? },
    allow_destroy: true

  validates :name, presence: true
  validates :plan_type, inclusion: { in: %w[km days both] }
  validates :km_interval, numericality: { greater_than: 0 }, allow_nil: true
  validates :days_interval, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :by_client, ->(client_id) { where(client_id: client_id) if client_id.present? }
  scope :km_based, -> { where(plan_type: %w[km both]) }
  scope :days_based, -> { where(plan_type: %w[days both]) }

  PLAN_TYPES = %w[km days both].freeze

  def service_count
    maintenance_plan_item_services.count
  end
end
