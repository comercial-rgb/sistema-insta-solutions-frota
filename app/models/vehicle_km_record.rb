class VehicleKmRecord < ApplicationRecord
  belongs_to :vehicle
  belongs_to :user
  belongs_to :order_service, optional: true

  validates :km, presence: true, numericality: { greater_than: 0 }
  validate :km_must_not_decrease

  after_create :update_vehicle_km
  after_create :check_maintenance_alerts

  scope :by_vehicle, ->(vehicle_id) { where(vehicle_id: vehicle_id) if vehicle_id.present? }
  scope :recent, -> { order(created_at: :desc) }

  ORIGINS = %w[manual vehicle_page order_service].freeze

  private

  def km_must_not_decrease
    last_record = VehicleKmRecord.where(vehicle_id: vehicle_id)
                                  .where.not(id: id)
                                  .order(created_at: :desc)
                                  .first
    if last_record && km.present? && km < last_record.km
      errors.add(:km, "não pode ser menor que o último registro (#{last_record.km} km)")
    end
  end

  def update_vehicle_km
    vehicle.update_column(:km, km) if vehicle.respond_to?(:km)
  end

  def check_maintenance_alerts
    MaintenanceAlertService.check_for_vehicle(vehicle) if defined?(MaintenanceAlertService)
  end
end
