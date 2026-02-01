class OrderServiceStatus < ApplicationRecord
  after_initialize :default_values

  default_scope {
    order(:id)
  }

  TEMP_REJEITADA_ID = -1
  EM_ABERTO_ID = 1
  AGUARDANDO_AVALIACAO_PROPOSTA_ID = 2
  APROVADA_ID = 3
  NOTA_FISCAL_INSERIDA_ID = 4
  AUTORIZADA_ID = 5
  AGUARDANDO_PAGAMENTO_ID = 6
  PAGA_ID = 7
  CANCELADA_ID = 8
  EM_CADASTRO_ID = 9
  EM_REAVALIACAO_ID = 10
  AGUARDANDO_APROVACAO_COMPLEMENTO_ID = 11

  REQUIRED_ORDER_SERVICE_STATUSES = [
    OrderServiceStatus::APROVADA_ID,
    OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID,
    OrderServiceStatus::AUTORIZADA_ID,
    OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID,
    OrderServiceStatus::PAGA_ID
  ]

  scope :by_id, lambda { |value| where("order_service_statuses.id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(order_service_statuses.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  
  # Ordenação customizada para o menu (Em reavaliação após Em aberto)
  # IMPORTANTE: EM_CADASTRO_ID não está aqui pois aparece separadamente no topo do menu (propostas em cadastro)
  MENU_ORDER = [
    EM_ABERTO_ID,             # 1
    EM_REAVALIACAO_ID,        # 10
    AGUARDANDO_AVALIACAO_PROPOSTA_ID,  # 2
    APROVADA_ID,              # 3
    NOTA_FISCAL_INSERIDA_ID,  # 4
    AUTORIZADA_ID,            # 5
    AGUARDANDO_PAGAMENTO_ID,  # 6
    PAGA_ID,                  # 7
    CANCELADA_ID              # 8
  ]
  
  scope :menu_ordered, -> {
    order_clause = MENU_ORDER.each_with_index.map { |id, index| "WHEN id = #{id} THEN #{index}" }.join(' ')
    unscoped.order(Arel.sql("CASE #{order_clause} ELSE 999 END"))
  }

  scope :by_initial_date, lambda { |value| where("order_service_statuses.created_at >= '#{value} 00:00:00'") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("order_service_statuses.created_at <= '#{value} 23:59:59'") if !value.nil? && !value.blank? }

  def get_text_name
    self.id.to_s
  end

  private

  def default_values
  end

end
