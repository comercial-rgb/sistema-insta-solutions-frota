class OrderServiceStatus < ApplicationRecord
  after_initialize :default_values

  default_scope {
    order(:id)
  }

  # ATENÇÃO: Estes IDs correspondem ao banco de dados ANTES da renumeração (seeds antigos).
  # Os seeds novos (populate_default.rb) definem IDs diferentes:
  #   Em cadastro=1, Em aberto=2, Em reavaliação=3, Ag. avaliação=4,
  #   Aprovada=5, NF inserida=6, Autorizada=7, Ag. pagamento=8, Paga=9, Cancelada=10
  # 
  # Se o script sync_status_ids.rb foi executado, os IDs do banco seguem a nova ordem.
  # Use os scopes que suportam ambos os IDs para consultas de histórico/audits.
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
  
  # IDs da nova numeração (após sync_status_ids.rb)
  # Usados como fallback nos scopes que consultam audits
  NEW_AUTORIZADA_ID = 7
  NEW_NOTA_FISCAL_INSERIDA_ID = 6

  REQUIRED_ORDER_SERVICE_STATUSES = [
    OrderServiceStatus::APROVADA_ID,
    OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID,
    OrderServiceStatus::AUTORIZADA_ID,
    OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID,
    OrderServiceStatus::PAGA_ID,
    # IDs da nova numeração para compatibilidade
    5, 6, 7, 8, 9
  ].uniq

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

  scope :by_initial_date, lambda { |value| where("order_service_statuses.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("order_service_statuses.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

  def get_text_name
    self.id.to_s
  end

  private

  def default_values
  end

end
