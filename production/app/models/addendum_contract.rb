class AddendumContract < ApplicationRecord
  after_initialize :default_values

  default_scope {
    order(:number)
  }

  scope :by_id, lambda { |value| where("addendum_contracts.id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(addendum_contracts.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("addendum_contracts.created_at >= '#{value} 00:00:00'") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("addendum_contracts.created_at <= '#{value} 23:59:59'") if !value.nil? && !value.blank? }

  belongs_to :contract, optional: true

  def get_text_name
    self.number.to_s
  end

  # Verifica se o aditivo pode ser excluído
  # Não pode excluir se o contrato já foi usado para criar empenhos
  # que dependem do valor deste aditivo
  def can_delete?
    return true if contract.nil?
    
    # Valor total do contrato sem este aditivo
    total_without_this = contract.total_value.to_f + 
      contract.addendum_contracts.where.not(id: self.id).where(active: true).sum(:total_value).to_f
    
    # Valor já utilizado em empenhos
    used_value = contract.get_used_value
    
    # Se o valor usado é maior que o total sem este aditivo,
    # significa que os empenhos dependem deste aditivo
    used_value <= total_without_this
  end

  def reason_cannot_delete
    return nil if can_delete?
    
    used_value = contract.get_used_value
    total_without_this = contract.total_value.to_f + 
      contract.addendum_contracts.where.not(id: self.id).where(active: true).sum(:total_value).to_f
    
    "Este aditivo não pode ser excluído pois o contrato possui empenhos que dependem do seu valor. " \
    "Valor utilizado em empenhos: #{ActionController::Base.helpers.number_to_currency(used_value, unit: 'R$ ', separator: ',', delimiter: '.')}. " \
    "Valor do contrato sem este aditivo: #{ActionController::Base.helpers.number_to_currency(total_without_this, unit: 'R$ ', separator: ',', delimiter: '.')}."
  end

	def total_value=(new_total_value)
		self[:total_value] = CustomHelper.currency_to_value(new_total_value)
	end

  private

  def default_values
    self.name ||= ''
    self.number ||= ''
    self.total_value ||= 0
    self.active = true if self.active.nil?
  end

end
