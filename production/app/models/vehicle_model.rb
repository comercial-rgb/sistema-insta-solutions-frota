class VehicleModel < ApplicationRecord
  # Relacionamentos
  belongs_to :vehicle_type
  has_many :vehicles, dependent: :nullify
  has_many :reference_prices, dependent: :destroy
  
  # Validações
  validates :brand, presence: true
  validates :model, presence: true
  validates :code_cilia, uniqueness: true, allow_blank: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_vehicle_type, ->(type_id) { where(vehicle_type_id: type_id) if type_id.present? }
  scope :by_brand, ->(brand) { where('LOWER(brand) LIKE ?', "%#{brand.to_s.downcase}%") if brand.present? }
  scope :by_model, ->(model) { where('LOWER(model) LIKE ?', "%#{model.to_s.downcase}%") if model.present? }
  scope :ordered, -> { order(:brand, :model, :version) }
  
  # Callbacks
  before_save :set_full_name
  before_save :normalize_brand_model
  
  # Métodos de instância
  def display_name
    parts = [brand, model, version].compact
    parts.join(' ')
  end
  
  def reference_prices_count
    reference_prices.active.count
  end
  
  # Busca por texto com matching inteligente
  def self.find_by_text_match(text:, vehicle_type_id:)
    return nil if text.blank?
    
    normalized_text = normalize_text(text)
    
    by_vehicle_type(vehicle_type_id).active.find do |vm|
      # Match exato por full_name normalizado
      return vm if normalize_text(vm.full_name) == normalized_text
      
      # Match por aliases
      if vm.aliases.present?
        begin
          aliases_array = JSON.parse(vm.aliases)
          return vm if aliases_array.any? { |a| normalize_text(a) == normalized_text }
        rescue JSON::ParserError
          # Ignora se não for JSON válido
        end
      end
      
      # Match parcial (brand + model)
      search_pattern = normalize_text("#{vm.brand} #{vm.model}")
      return vm if normalized_text.include?(search_pattern)
    end
    
    nil
  end
  
  def self.normalize_text(text)
    return '' if text.blank?
    text.to_s.upcase
        .gsub(/[\/\-_]/, ' ')
        .gsub(/\s+/, ' ')
        .strip
  end
  
  private
  
  def set_full_name
    self.full_name = display_name if full_name.blank?
  end
  
  def normalize_brand_model
    self.brand = brand.to_s.upcase.strip if brand.present?
    self.model = model.to_s.upcase.strip if model.present?
  end
end
