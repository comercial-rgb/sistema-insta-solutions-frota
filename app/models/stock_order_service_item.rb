class StockOrderServiceItem < ApplicationRecord
  # Associations
  belongs_to :order_service
  belongs_to :stock_item
  belongs_to :added_by, class_name: 'User'

  # Enums
  enum labor_type: {
    credentialed_network: 0,
    own_labor: 1
  }

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :stock_item_id, uniqueness: { scope: :order_service_id, message: 'já foi adicionado a esta OS' }
  validate :validate_stock_availability

  # Callbacks
  after_create :consume_stock
  after_destroy :return_stock

  # Scopes
  scope :by_order_service_id, ->(os_id) { where(order_service_id: os_id) if os_id.present? }
  scope :by_stock_item_id, ->(item_id) { where(stock_item_id: item_id) if item_id.present? }
  scope :by_labor_type, ->(labor_type) { where(labor_type: labor_type) if labor_type.present? }

  # Methods
  def stock_item_name
    stock_item&.formatted_name
  end

  def total_value
    (quantity || 0) * (unit_price || stock_item&.unit_price || 0)
  end

  def labor_type_label
    I18n.t("activerecord.attributes.stock_order_service_item.labor_types.#{labor_type}")
  end

  private

  def validate_stock_availability
    return unless stock_item && quantity

    if new_record? && quantity > stock_item.quantity
      errors.add(:quantity, "excede o estoque disponível (#{stock_item.quantity} #{stock_item.unit_measure})")
    elsif persisted?
      original = StockOrderServiceItem.find(id)
      diff = quantity - original.quantity
      if diff > 0 && diff > stock_item.quantity
        errors.add(:quantity, "excede o estoque disponível (#{stock_item.quantity} #{stock_item.unit_measure})")
      end
    end
  end

  def consume_stock
    stock_item.remove_stock(
      quantity,
      added_by,
      order_service: order_service,
      source: :order_service_usage,
      reason: "Consumo na OS #{order_service.code}"
    )
  end

  def return_stock
    stock_item.add_stock(
      quantity,
      added_by,
      order_service: order_service,
      source: :order_service_usage,
      reason: "Devolução ao estoque - OS #{order_service.code} (item removido)"
    )
  end
end
