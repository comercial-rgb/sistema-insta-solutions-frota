class ServiceGroupItem < ApplicationRecord
  audited

  # Associations
  belongs_to :service_group
  belongs_to :service

  # Validations
  validates :service_id, presence: true
  validates :service_id, uniqueness: { scope: :service_group_id, message: "já está adicionado neste grupo" }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :max_value, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  default_scope { order(:id) }
  
  scope :by_service_group_id, lambda { |value| where(service_group_id: value) if value.present? }
  scope :by_service_id, lambda { |value| where(service_id: value) if value.present? }

  def service_name
    service&.name
  end

  def formatted_max_value
    ActionController::Base.helpers.number_to_currency(max_value, unit: "R$ ", separator: ",", delimiter: ".")
  end

  def formatted_quantity
    ActionController::Base.helpers.number_with_precision(quantity, precision: 2, separator: ",", delimiter: ".")
  end
end
