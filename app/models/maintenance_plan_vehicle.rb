class MaintenancePlanVehicle < ApplicationRecord
  belongs_to :maintenance_plan
  belongs_to :vehicle

  validates :vehicle_id, uniqueness: { scope: :maintenance_plan_id, message: 'já está vinculado a este plano' }
end
