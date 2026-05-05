class DriverVehicleAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :vehicle

  scope :active_assignments, -> { where(active: true) }

  validates :user_id, uniqueness: { scope: [:vehicle_id, :active], message: 'já está vinculado a este veículo' }, if: :active?

  def active?
    active == true
  end
end
