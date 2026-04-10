class VehicleChecklistItem < ApplicationRecord
  belongs_to :vehicle_checklist

  CATEGORIES = %w[motor freios pneus eletrica carroceria interior luzes fluidos documentacao outros].freeze
  CONDITIONS = %w[ok attention critical na].freeze

  validates :category, inclusion: { in: CATEGORIES }
  validates :condition, inclusion: { in: CONDITIONS }
  validates :item_name, presence: true

  scope :with_anomaly, -> { where(has_anomaly: true) }
  scope :by_category, ->(cat) { where(category: cat) if cat.present? }
end
