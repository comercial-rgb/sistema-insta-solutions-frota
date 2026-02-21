class OrderServiceInvoice < ApplicationRecord
  after_initialize :default_values

  default_scope {
    order(:number)
  }

  scope :by_id, lambda { |value| where("order_service_invoices.id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(order_service_invoices.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("order_service_invoices.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("order_service_invoices.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

  belongs_to :order_service_proposal, optional: true
  belongs_to :order_service_invoice_type, optional: true

  # validates_presence_of :number, :value, :order_service_invoice_type_id, :emission_date, :file

  has_one_attached :file

  def value=(new_value)
    self[:value] = CustomHelper.currency_to_value(new_value)
  end

  def get_text_name
    self.number.to_s
  end

  private

  def default_values
    self.number ||= ""
  end

end
