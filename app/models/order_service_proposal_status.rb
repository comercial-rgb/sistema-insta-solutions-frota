class OrderServiceProposalStatus < ApplicationRecord
  after_initialize :default_values

  # IDs conforme banco de dados real (order_service_proposal_statuses)
  # 1=Em aberto, 2=Aguardando avaliação, 3=Aprovada, 4=Notas fiscais inseridas
  # 5=Autorizada, 6=Aguardando pagamento, 7=Paga, 8=Proposta reprovada
  # 9=Cancelada, 10=Em cadastro, 11=Aguardando aprovação de complemento
  EM_ABERTO_ID = 1
  AGUARDANDO_AVALIACAO_ID = 2
  APROVADA_ID = 3
  NOTAS_INSERIDAS_ID = 4
  AUTORIZADA_ID = 5
  AGUARDANDO_PAGAMENTO_ID = 6
  PAGA_ID = 7
  PROPOSTA_REPROVADA_ID = 8
  CANCELADA_ID = 9
  EM_CADASTRO_ID = 10
  AGUARDANDO_APROVACAO_COMPLEMENTO_ID = 11

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
