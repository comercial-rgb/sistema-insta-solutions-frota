class StockMovement < ApplicationRecord
  # Associations
  belongs_to :stock_item
  belongs_to :user
  belongs_to :order_service, optional: true

  # Enums
  enum movement_type: {
    entry: 0,
    exit: 1,
    adjustment_entry: 2,
    adjustment_exit: 3,
    os_consumption: 4,
    os_return: 5
  }

  enum source: {
    manual: 0,
    xml_import: 1,
    order_service_usage: 2,
    adjustment: 3
  }

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :balance_after, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :movement_type, presence: true

  # Scopes
  scope :by_stock_item_id, ->(stock_item_id) { where(stock_item_id: stock_item_id) if stock_item_id.present? }
  scope :by_movement_type, ->(movement_type) { where(movement_type: movement_type) if movement_type.present? }
  scope :by_source, ->(source) { where(source: source) if source.present? }
  scope :by_user_id, ->(user_id) { where(user_id: user_id) if user_id.present? }
  scope :by_document_number, ->(doc) { where("stock_movements.document_number LIKE ?", "%#{doc}%") if doc.present? }
  scope :by_initial_date, ->(date) { where("stock_movements.created_at >= ?", date.beginning_of_day) if date.present? }
  scope :by_final_date, ->(date) { where("stock_movements.created_at <= ?", date.end_of_day) if date.present? }
  scope :entry_movements, -> { where(movement_type: [:entry, :adjustment_entry, :os_return]) }
  scope :exit_movements, -> { where(movement_type: [:exit, :adjustment_exit, :os_consumption]) }

  # Methods
  def is_entry?
    entry? || adjustment_entry? || os_return?
  end

  def is_exit?
    exit? || adjustment_exit? || os_consumption?
  end

  def movement_type_label
    I18n.t("activerecord.attributes.stock_movement.movement_types.#{movement_type}")
  end

  def source_label
    I18n.t("activerecord.attributes.stock_movement.sources.#{source}")
  end

  def user_name
    user&.name
  end

  def stock_item_name
    stock_item&.formatted_name
  end
end
