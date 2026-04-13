class MaintenancePlanItemService < ApplicationRecord
  belongs_to :maintenance_plan_item
  belongs_to :service

  validates :quantity, numericality: { greater_than: 0 }, allow_nil: false
  validates :service_id, uniqueness: { scope: :maintenance_plan_item_id, message: 'já está vinculado a este item' }
end
