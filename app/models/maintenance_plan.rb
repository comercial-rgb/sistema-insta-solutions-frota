class MaintenancePlan < ApplicationRecord
  after_initialize :default_values

  belongs_to :client, class_name: 'User', optional: true
  has_many :maintenance_plan_items, dependent: :destroy
  has_many :maintenance_plan_vehicles, dependent: :destroy
  has_many :vehicles, through: :maintenance_plan_vehicles

  accepts_nested_attributes_for :maintenance_plan_items, reject_if: :all_blank, allow_destroy: true

  validates :name, presence: true

  default_scope { order(:id) }

  scope :by_id, lambda { |value| where("maintenance_plans.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_client, lambda { |client_id| where(client_id: client_id) if client_id.present? }
  scope :by_initial_date, lambda { |value| where("maintenance_plans.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("maintenance_plans.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }
  scope :active, -> { where(active: true) }

  def get_text_name
    self.name.present? ? self.name : self.id.to_s
  end

  def vehicle_count
    maintenance_plan_vehicles.count
  end

  def item_count
    maintenance_plan_items.count
  end

  private

  def default_values
  end
end
