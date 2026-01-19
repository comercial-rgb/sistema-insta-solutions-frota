class ProviderServiceTemp < ApplicationRecord
  after_initialize :default_values
  before_validation :recalculate_totals_from_client_discount
  before_validation :sync_quantity_from_order_service, if: Proc.new { |obj|
    obj.order_service_proposal.present? &&
      obj.order_service_proposal.order_service.present? &&
      [OrderServiceType::COTACOES_ID, OrderServiceType::REQUISICAO_ID].include?(obj.order_service_proposal.order_service.order_service_type_id) &&
      obj.order_service_proposal.skip_validation != true
  }

  default_scope {
    order(:id)
  }

  attr_accessor :discount_temp, :total_temp

  scope :by_id, lambda { |value| where("provider_service_temps.id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(provider_service_temps.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("provider_service_temps.created_at >= '#{value} 00:00:00'") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("provider_service_temps.created_at <= '#{value} 23:59:59'") if !value.nil? && !value.blank? }

  belongs_to :order_service_proposal, optional: true, inverse_of: :provider_service_temps
  belongs_to :category, optional: true
  belongs_to :service, optional: true

  validates_presence_of :price, :warranty_period, if: Proc.new { |obj| obj.order_service_proposal.skip_validation != true }
  validates_numericality_of :price, greater_than: 0, if: Proc.new { |obj| obj.order_service_proposal.skip_validation != true }
  validates_numericality_of :warranty_period, greater_than_or_equal_to: 30, if: Proc.new { |obj| obj.order_service_proposal.skip_validation != true }
  validates_presence_of :brand, if: Proc.new { |obj| obj.order_service_proposal.skip_validation != true && obj.category_id == Category::SERVICOS_PECAS_ID }
  
  # Validação de limites do grupo de serviços (para Requisições)
  validate :validate_service_group_limits, if: Proc.new { |obj| 
    obj.order_service_proposal.present? && 
    obj.order_service_proposal.order_service.present? &&
    obj.order_service_proposal.order_service.order_service_type_id == OrderServiceType::REQUISICAO_ID &&
    obj.order_service_proposal.order_service.service_group_id.present? &&
    obj.order_service_proposal.skip_validation != true
  }

  def get_text_name
    self.id.to_s
  end

  def price=(new_price)
    self[:price] = CustomHelper.currency_to_value(new_price)
  end

  def getting_name_and_description
    # Se tem service associado (item do banco), usa service.name
    # Se não tem service (item novo criado), usa self.name
    if self.service.present?
      desc = self.description.present? ? " - Obs: #{self.description}" : ""
      return "#{self.service.name}#{desc}"
    else
      # Item novo sem service_id (foi criado manualmente)
      desc = self.description.present? ? " - Obs: #{self.description}" : ""
      return "#{self.name}#{desc}"
    end
  end

  private

  def recalculate_totals_from_client_discount
    return unless order_service_proposal&.order_service&.client.present?

    quantity = (self.quantity.presence || 0).to_d
    unity_value = (self.price.presence || 0).to_d
    total_without_discount = (unity_value * quantity)

    discount_percent = order_service_proposal.order_service.client.discount_percent.to_d
    discount_value = (total_without_discount * (discount_percent / 100)).round(2)

    self.discount = discount_value
    self.total_value = (total_without_discount - discount_value).round(2)
  end

  def default_values
    self.name ||= ""
    self.code ||= ""
    self.price ||= 0
    self.description ||= ""
    self.quantity ||= 1
    self.discount ||= 0
    self.total_value ||= 0
    self.category_id ||= Category::SERVICOS_PECAS_ID
  end

  def validate_service_group_limits
    return unless order_service_proposal&.order_service&.service_group.present?
    return unless service_id.present?

    service_group = order_service_proposal.order_service.service_group
    group_item = service_group.service_group_items.find_by(service_id: service_id)
    
    return unless group_item # Se não encontrar o item no grupo, outra validação deve pegar

    # Validar se o preço unitário excede o valor máximo do grupo
    item_price = price || 0
    max_value = group_item.max_value || 0

    if item_price > max_value
      errors.add(:price, "O valor unitário proposto (R$ #{ActionController::Base.helpers.number_to_currency(item_price, unit: '', separator: ',', delimiter: '.')}) excede o limite máximo permitido para '#{service.name}' no grupo de serviços (máximo: #{group_item.formatted_max_value})")
    end
  end

  def sync_quantity_from_order_service
    return unless order_service_proposal&.order_service.present?
    return unless service_id.present?

    os = order_service_proposal.order_service
    os_qty = os.part_service_order_services.where(service_id: service_id).sum(:quantity)

    # Se não encontrou item correspondente na OS, não altera aqui.
    return if os_qty.nil? || os_qty.to_i <= 0

    self.quantity = os_qty.to_i
  end

end
