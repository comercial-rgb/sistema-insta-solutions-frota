class OrderServiceProposalItem < ApplicationRecord
  after_initialize :default_values
  before_validation :recalculate_totals
  # validate :check_reference_price, if: :should_validate_price?
  # ⚠️ Validação desabilitada - agora apenas mostra aviso visual (não bloqueia)

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

  # Verifica se o preço do item excede a referência Cilia
  # Retorna hash com informações para exibição de badges e justificativas
  def price_vs_reference
    result = {
      exceeded: false,
      percentage: 0,
      reference_price: nil,
      max_allowed: nil,
      current_price: unity_value.to_f
    }
    
    return result unless should_validate_price?
    return result unless unity_value.present?
    
    vehicle = order_service_proposal.order_service.vehicle
    ref_price = ReferencePrice.find_for_vehicle_and_service(
      vehicle_id: vehicle.id,
      service_id: service_id
    )
    
    return result unless ref_price
    
    max_allowed = ref_price.max_allowed_price
    result[:reference_price] = ref_price.reference_price.to_f
    result[:max_allowed] = max_allowed.to_f
    
    if unity_value > max_allowed
      percentage_over = (((unity_value - ref_price.reference_price) / ref_price.reference_price) * 100).round(0)
      result[:exceeded] = true
      result[:percentage] = percentage_over
    end
    
    result
  end
  
  def should_validate_price?
    # Valida apenas se for peça e tiver veículo vinculado a um modelo
    return false unless service_id.present?
    return false unless order_service_proposal&.order_service&.vehicle.present?
    return false unless get_category_id == Category::SERVICOS_PECAS_ID
    
    vehicle = order_service_proposal.order_service.vehicle
    vehicle.vehicle_model_id.present?
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
  
  def check_reference_price
    return unless unity_value.present?
    
    vehicle = order_service_proposal.order_service.vehicle
    ref_price = ReferencePrice.find_for_vehicle_and_service(
      vehicle_id: vehicle.id,
      service_id: service_id
    )
    
    if ref_price
      max_allowed = ref_price.max_allowed_price
      
      if unity_value > max_allowed
        errors.add(:unity_value, 
          "R$ #{CustomHelper.to_currency(unity_value)} excede o máximo permitido de #{CustomHelper.to_currency(max_allowed)} " +
          "(Ref. Cilia: #{CustomHelper.to_currency(ref_price.reference_price)} + #{ref_price.percentage_increase}%)"
        )
      end
    end
  end

end
