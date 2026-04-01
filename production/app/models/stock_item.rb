class StockItem < ApplicationRecord
  # Associations
  belongs_to :client, class_name: 'User'
  belongs_to :cost_center
  belongs_to :sub_unit, optional: true
  belongs_to :category, optional: true
  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User', optional: true

  has_many :stock_movements, dependent: :destroy
  has_many :stock_order_service_items, dependent: :restrict_with_error

  # Enums
  enum status: { active: 0, inactive: 1, below_minimum: 2 }

  # Validations
  validates :name, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :minimum_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :code, uniqueness: { scope: [:client_id, :cost_center_id], message: 'já existe neste centro de custo' }, allow_blank: true

  # Callbacks
  after_save :check_minimum_quantity

  # Scopes
  scope :by_client_id, ->(client_id) { where(client_id: client_id) if client_id.present? }
  scope :by_cost_center_id, ->(cost_center_id) { where(cost_center_id: cost_center_id) if cost_center_id.present? }
  scope :by_sub_unit_id, ->(sub_unit_id) { where(sub_unit_id: sub_unit_id) if sub_unit_id.present? }
  scope :by_name, ->(name) { where("stock_items.name LIKE ?", "%#{name}%") if name.present? }
  scope :by_code, ->(code) { where("stock_items.code LIKE ?", "%#{code}%") if code.present? }
  scope :by_brand, ->(brand) { where("stock_items.brand LIKE ?", "%#{brand}%") if brand.present? }
  scope :by_part_number, ->(part_number) { where("stock_items.part_number LIKE ?", "%#{part_number}%") if part_number.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_category_id, ->(category_id) { where(category_id: category_id) if category_id.present? }
  scope :below_minimum_stock, -> { where("stock_items.quantity <= stock_items.minimum_quantity AND stock_items.minimum_quantity > 0") }
  scope :with_stock, -> { where("stock_items.quantity > 0") }
  scope :by_ids, ->(ids) { where(id: ids) if ids.present? }
  scope :by_cost_center_or_sub_unit_ids, ->(cost_center_ids, sub_unit_ids) {
    if cost_center_ids.present? || sub_unit_ids.present?
      conditions = []
      conditions << "stock_items.cost_center_id IN (#{cost_center_ids.join(',')})" if cost_center_ids.present?
      conditions << "stock_items.sub_unit_id IN (#{sub_unit_ids.join(',')})" if sub_unit_ids.present?
      where(conditions.join(' OR '))
    end
  }

  # Methods
  def formatted_name
    parts = [name]
    parts << "(#{code})" if code.present?
    parts << "- #{brand}" if brand.present?
    parts.join(' ')
  end

  def formatted_name_with_stock
    "#{formatted_name} [Qtd: #{quantity} #{unit_measure}]"
  end

  def total_value
    (quantity || 0) * (unit_price || 0)
  end

  def is_below_minimum?
    minimum_quantity.present? && minimum_quantity > 0 && quantity <= minimum_quantity
  end

  def cost_center_name
    cost_center&.name
  end

  def sub_unit_name
    sub_unit&.name
  end

  def client_name
    client&.name
  end

  def created_by_name
    created_by&.name
  end

  # Registro de entrada no estoque
  def add_stock(quantity_to_add, user, attrs = {})
    return false if quantity_to_add.to_f <= 0

    ActiveRecord::Base.transaction do
      new_balance = self.quantity + quantity_to_add.to_f
      self.update!(quantity: new_balance, updated_by: user)

      stock_movements.create!(
        user: user,
        movement_type: :entry,
        quantity: quantity_to_add.to_f,
        unit_price: attrs[:unit_price] || self.unit_price,
        balance_after: new_balance,
        reason: attrs[:reason],
        document_number: attrs[:document_number],
        supplier_name: attrs[:supplier_name],
        supplier_cnpj: attrs[:supplier_cnpj],
        xml_file_name: attrs[:xml_file_name],
        source: attrs[:source] || :manual
      )
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  # Registro de saída do estoque
  def remove_stock(quantity_to_remove, user, attrs = {})
    return false if quantity_to_remove.to_f <= 0
    return false if quantity_to_remove.to_f > self.quantity

    ActiveRecord::Base.transaction do
      new_balance = self.quantity - quantity_to_remove.to_f
      self.update!(quantity: new_balance, updated_by: user)

      stock_movements.create!(
        user: user,
        movement_type: :exit,
        quantity: quantity_to_remove.to_f,
        unit_price: attrs[:unit_price] || self.unit_price,
        balance_after: new_balance,
        reason: attrs[:reason],
        order_service: attrs[:order_service],
        source: attrs[:source] || :manual
      )
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  # Ajuste de estoque (pode ser positivo ou negativo)
  def adjust_stock(new_quantity, user, reason)
    return false if new_quantity.to_f < 0

    ActiveRecord::Base.transaction do
      diff = new_quantity.to_f - self.quantity
      movement_type = diff >= 0 ? :adjustment_entry : :adjustment_exit

      self.update!(quantity: new_quantity.to_f, updated_by: user)

      stock_movements.create!(
        user: user,
        movement_type: movement_type,
        quantity: diff.abs,
        balance_after: new_quantity.to_f,
        reason: reason,
        source: :adjustment
      )
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  def check_minimum_quantity
    if is_below_minimum? && !below_minimum?
      update_column(:status, :below_minimum)
    elsif below_minimum? && !is_below_minimum?
      update_column(:status, :active)
    end
  end
end
