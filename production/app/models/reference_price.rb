class ReferencePrice < ApplicationRecord
  # Relacionamentos
  belongs_to :vehicle_model
  belongs_to :service
  
  # Validações
  validates :reference_price, presence: true, numericality: { greater_than: 0 }
  validates :max_percentage, presence: true, numericality: { greater_than_or_equal_to: 100 }
  validates :service_id, uniqueness: { scope: :vehicle_model_id, message: 'já possui preço de referência para este modelo de veículo' }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_vehicle_model, ->(model_id) { where(vehicle_model_id: model_id) if model_id.present? }
  scope :by_service, ->(service_id) { where(service_id: service_id) if service_id.present? }
  scope :ordered, -> { joins(:service).order('services.name') }
  
  # Callbacks
  before_validation :set_defaults
  
  # Métodos de instância
  def max_allowed_price
    return 0 if reference_price.nil? || max_percentage.nil?
    (reference_price * max_percentage / 100.0).round(2)
  end
  
  def formatted_reference_price
    CustomHelper.to_currency(reference_price)
  end
  
  def formatted_max_allowed_price
    CustomHelper.to_currency(max_allowed_price)
  end
  
  def percentage_increase
    return 0 if max_percentage.nil?
    (max_percentage - 100).round(2)
  end
  
  # Busca preço de referência para um veículo e serviço específicos
  def self.find_for_vehicle_and_service(vehicle_id:, service_id:)
    return nil if vehicle_id.blank? || service_id.blank?
    
    vehicle = Vehicle.find_by(id: vehicle_id)
    return nil unless vehicle&.vehicle_model_id
    
    active
      .by_vehicle_model(vehicle.vehicle_model_id)
      .by_service(service_id)
      .first
  end
  
  private
  
  def set_defaults
    self.max_percentage ||= 110.0
    self.active = true if active.nil?
  end
end
