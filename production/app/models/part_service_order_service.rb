class PartServiceOrderService < ApplicationRecord
  after_initialize :default_values

  default_scope {
    order(:id)
  }

  scope :by_id, lambda { |value| where("part_service_order_services.id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(part_service_order_services.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("part_service_order_services.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("part_service_order_services.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

  belongs_to :order_service, optional: true
  belongs_to :service, optional: true
  belongs_to :category, optional: true

  def get_text_name
    self.id.to_s
  end
  
  # Categoria persistida na linha (category_id) ou derivada do serviço do catálogo
  def effective_category_id
    read_attribute(:category_id).presence || service&.category_id
  end

  # Empenho na OS: itens sem service_id não podem sumir do joins(:service).
  # Sem categoria explícita, assume peças (alinhado à proposta / ProviderServiceTemp).
  def category_id_for_commitment
    cid = effective_category_id
    return cid if cid.present?

    return Category::SERVICOS_PECAS_ID if service_id.blank?

    service&.category_id || Category::SERVICOS_PECAS_ID
  end

  private

  def default_values
    self.observation ||= ""
  end

end
