class PartServiceOrderService < ApplicationRecord
  after_initialize :default_values
  attr_accessor :category_id

  default_scope {
    order(:id)
  }

  scope :by_id, lambda { |value| where("part_service_order_services.id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(part_service_order_services.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("part_service_order_services.created_at >= '#{value} 00:00:00'") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("part_service_order_services.created_at <= '#{value} 23:59:59'") if !value.nil? && !value.blank? }

  belongs_to :order_service, optional: true
  belongs_to :service, optional: true

  def get_text_name
    self.id.to_s
  end
  
  # Retorna a categoria do item (usa attr_accessor se definido, caso contrário pega do serviço)
  def effective_category_id
    category_id.presence || service&.category_id
  end

  private

  def default_values
    self.observation ||= ""
  end

end
