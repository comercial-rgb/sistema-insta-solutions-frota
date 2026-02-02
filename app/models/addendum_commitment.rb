class AddendumCommitment < ApplicationRecord
  after_initialize :default_values

  belongs_to :commitment
  belongs_to :contract, optional: true

  validates :number, :total_value, presence: true
  validates :total_value, numericality: { greater_than: 0 }
  validate :validate_contract_available_value, if: -> { contract_id.present? && total_value.present? }

  default_scope { order(created_at: :asc) }

  def get_text_name
    self.number.to_s
  end

  # Verifica se o aditivo pode ser excluído
  # Não pode excluir se o empenho já foi usado e depende do valor deste aditivo
  def can_delete?
    return true if commitment.nil?
    
    # Valor total do empenho sem este aditivo
    total_without_this = commitment.commitment_value.to_f + 
      commitment.addendum_commitments.where.not(id: self.id).where(active: true).sum(:total_value).to_f
    
    # Valor já utilizado
    used_value = Commitment.get_total_already_consumed_value(commitment)
    
    # Se o valor usado é maior que o total sem este aditivo,
    # significa que os empenhos dependem deste aditivo
    used_value <= total_without_this
  end

  def reason_cannot_delete
    return nil if can_delete?
    
    used_value = Commitment.get_total_already_consumed_value(commitment)
    total_without_this = commitment.commitment_value.to_f + 
      commitment.addendum_commitments.where.not(id: self.id).where(active: true).sum(:total_value).to_f
    
    "Este aditivo não pode ser excluído pois o empenho possui valores consumidos que dependem deste aditivo. " \
    "Valor utilizado: #{ActionController::Base.helpers.number_to_currency(used_value, unit: 'R$ ', separator: ',', delimiter: '.')}. " \
    "Valor do empenho sem este aditivo: #{ActionController::Base.helpers.number_to_currency(total_without_this, unit: 'R$ ', separator: ',', delimiter: '.')}."
  end

  def total_value=(new_total_value)
    self[:total_value] = CustomHelper.currency_to_value(new_total_value)
  end

  private

  def default_values
    self.active = true if self.active.nil?
  end

  def validate_contract_available_value
    return unless contract.present?
    
    # Valor disponível no contrato (excluindo o empenho atual)
    available = contract.get_disponible_value(commitment_id)
    
    if total_value > available
      errors.add(:total_value, "não pode ser maior que o valor disponível no contrato (#{CustomHelper.to_currency(available)})")
    end
  end
end
