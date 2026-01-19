class OrderServiceProposalItem < ApplicationRecord
  after_initialize :default_values
  before_validation :recalculate_totals

  default_scope {
    order(:id)
  }

  attr_accessor :discount_temp, :total_temp, :item_category_id

  scope :by_id, lambda { |value| where("order_service_proposal_items.id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(order_service_proposal_items.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("order_service_proposal_items.created_at >= '#{value} 00:00:00'") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("order_service_proposal_items.created_at <= '#{value} 23:59:59'") if !value.nil? && !value.blank? }

  belongs_to :order_service_proposal, optional: true
  belongs_to :service, optional: true

  # Retorna a category_id do service ou usa a categoria definida manualmente
  def get_category_id
    if self.service.present?
      self.service.category_id
    else
      # Para itens criados manualmente, tentar identificar pela proposta
      # Verifica se há um provider_service_temp correspondente pelo service_name
      if self.order_service_proposal.present?
        pst = self.order_service_proposal.provider_service_temps.find_by(name: self.service_name)
        pst&.category_id
      end
    end
  end

  def get_text_name
    self.id.to_s
  end

  private

  def recalculate_totals
    quantity = (self.quantity.presence || 0).to_d
    unity_value = (self.unity_value.presence || 0).to_d
    discount = (self.discount.presence || 0).to_d

    self.total_value_without_discount = (unity_value * quantity).round(2)
    self.total_value = (self.total_value_without_discount.to_d - discount).round(2)
  end

  def default_values
    self.quantity ||= 1
  end

end
