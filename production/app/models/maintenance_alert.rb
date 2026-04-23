class MaintenanceAlert < ApplicationRecord
  belongs_to :vehicle
  belongs_to :maintenance_plan_item
  belongs_to :client, class_name: 'User', optional: true
  belongs_to :acknowledged_by, class_name: 'User', optional: true
  belongs_to :order_service, optional: true

  scope :pending, -> { where(status: 'pending') }
  scope :by_vehicle, ->(vehicle_id) { where(vehicle_id: vehicle_id) if vehicle_id.present? }
  scope :by_client, ->(client_id) { where(client_id: client_id) if client_id.present? }
  scope :recent, -> { order(created_at: :desc) }

  STATUSES = %w[pending acknowledged completed dismissed].freeze
  ALERT_TYPES = %w[km days].freeze

  def acknowledge!(user)
    update!(status: 'acknowledged', acknowledged_by: user, acknowledged_at: Time.current)
  end

  def complete!
    update!(status: 'completed')
  end

  def dismiss!
    update!(status: 'dismissed')
  end
end
