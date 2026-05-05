class TrafficViolation < ApplicationRecord
  belongs_to :user
  belongs_to :vehicle
  belongs_to :client, class_name: 'User'

  VIOLATION_TYPES = %w[leve media grave gravissima].freeze
  STATUSES = %w[pending paid appealed cancelled].freeze

  validates :violation_date, presence: true
  validates :violation_type, inclusion: { in: VIOLATION_TYPES }, allow_blank: true
  validates :status, inclusion: { in: STATUSES }

  scope :by_user, ->(user_id) { where(user_id: user_id) if user_id.present? }
  scope :by_vehicle, ->(vehicle_id) { where(vehicle_id: vehicle_id) if vehicle_id.present? }
  scope :by_client, ->(client_id) { where(client_id: client_id) if client_id.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(violation_date: :desc) }

  def fine_value=(new_value)
    self[:fine_value] = CustomHelper.currency_to_value(new_value) rescue new_value
  end
end
