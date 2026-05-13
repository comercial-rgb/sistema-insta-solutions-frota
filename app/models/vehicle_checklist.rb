class VehicleChecklist < ApplicationRecord
  belongs_to :vehicle
  belongs_to :user
  belongs_to :client, class_name: 'User'
  belongs_to :cost_center, optional: true
  belongs_to :acknowledged_by, class_name: 'User', optional: true
  belongs_to :order_service, optional: true

  has_many :items, class_name: 'VehicleChecklistItem', dependent: :destroy
  has_many_attached :photos
  validates :photos, safe_file: { profile: :image }, if: -> { photos.attached? }

  accepts_nested_attributes_for :items, reject_if: :all_blank, allow_destroy: true

  STATUSES = %w[pending acknowledged os_created closed].freeze

  validates :status, inclusion: { in: STATUSES }

  scope :by_vehicle, ->(vehicle_id) { where(vehicle_id: vehicle_id) if vehicle_id.present? }
  scope :by_client, ->(client_id) { where(client_id: client_id) if client_id.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_user, ->(user_id) { where(user_id: user_id) if user_id.present? }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_anomalies, -> { joins(:items).where(vehicle_checklist_items: { has_anomaly: true }).distinct }

  def has_anomalies?
    items.where(has_anomaly: true).exists?
  end

  def anomaly_count
    items.where(has_anomaly: true).count
  end

  def acknowledge!(user)
    update!(
      status: 'acknowledged',
      acknowledged_at: Time.current,
      acknowledged_by: user
    )
  end

  def create_os_from_checklist!(order_service)
    update!(
      status: 'os_created',
      order_service: order_service
    )
  end
end
