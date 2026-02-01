class OrderServiceProposalStatus < ApplicationRecord
  after_initialize :default_values

  # IDs atualizados conforme banco de dados atual
  EM_CADASTRO_ID = 1
  AGUARDANDO_APROVACAO_COMPLEMENTO_ID = 11
  EM_ABERTO_ID = 12
  AGUARDANDO_AVALIACAO_ID = 13
  APROVADA_ID = 14
  NOTAS_INSERIDAS_ID = 15
  AUTORIZADA_ID = 16
  AGUARDANDO_PAGAMENTO_ID = 17
  PAGA_ID = 18
  PROPOSTA_REPROVADA_ID = 19
  CANCELADA_ID = 20

  REQUIRED_PROPOSAL_STATUSES = [
    OrderServiceProposalStatus::APROVADA_ID,
    OrderServiceProposalStatus::NOTAS_INSERIDAS_ID,
    OrderServiceProposalStatus::AUTORIZADA_ID,
    OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
    OrderServiceProposalStatus::PAGA_ID
  ]

  default_scope {
    order(:id)
  }

  scope :by_id, lambda { |value| where("order_service_proposal_statuses.id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(order_service_proposal_statuses.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("order_service_proposal_statuses.created_at >= '#{value} 00:00:00'") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("order_service_proposal_statuses.created_at <= '#{value} 23:59:59'") if !value.nil? && !value.blank? }

  def get_text_name
    self.id.to_s
  end

  private

  def default_values
  end

end
