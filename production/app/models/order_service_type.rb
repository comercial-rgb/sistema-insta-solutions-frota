class OrderServiceType < ApplicationRecord
  after_initialize :default_values

  COTACOES_ID = 1      # Cotações
  DIAGNOSTICO_ID = 2   # Diagnóstico (anteriormente Emergencial)
  REQUISICAO_ID = 3    # Requisição

  default_scope {
    order(:id)
  }

  scope :by_id, lambda { |value| where("order_service_types.id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(order_service_types.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("order_service_types.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("order_service_types.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

  def get_text_name
    self.name.to_s
  end

  private

  def default_values
  end

end
