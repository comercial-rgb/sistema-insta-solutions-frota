class Commitment < ApplicationRecord
  after_initialize :default_values

  attr_accessor :skip_validations

  default_scope {
    includes(:cancel_commitments)
    .order(commitment_number: :asc)
  }

  scope :by_id, lambda { |value| where("commitments.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_client_id, lambda { |value| where("commitments.client_id = ?", value) if !value.nil? && !value.blank? }
  
  # Scope atualizado para buscar por centro de custo na nova tabela de relacionamento ou na coluna legada
  scope :by_cost_center_id, lambda { |value|
    return if value.nil? || value.blank?
    joins("LEFT JOIN commitment_cost_centers ON commitment_cost_centers.commitment_id = commitments.id")
      .where("commitment_cost_centers.cost_center_id = :value OR commitments.cost_center_id = :value", value: value)
      .distinct
  }
  
  scope :by_cost_center_ids, lambda { |value|
    return if value.nil?
    joins("LEFT JOIN commitment_cost_centers ON commitment_cost_centers.commitment_id = commitments.id")
      .where("commitment_cost_centers.cost_center_id IN (:value) OR commitments.cost_center_id IN (:value)", value: value)
      .distinct
  }
  
  scope :by_sub_unit_id, lambda { |value| where("commitments.sub_unit_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_contract_id, lambda { |value| where("commitments.contract_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_commitment_number, lambda { |value| where("LOWER(commitments.commitment_number) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("commitments.created_at >= '#{value} 00:00:00'") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("commitments.created_at <= '#{value} 23:59:59'") if !value.nil? && !value.blank? }

  scope :by_initial_commitment_value, lambda { |value| where("commitments.commitment_value >= '#{value}'") if !value.nil? && !value.blank? }
	scope :by_final_commitment_value, lambda { |value| where("commitments.commitment_value <= '#{value}'") if !value.nil? && !value.blank? }

  # Scope atualizado para buscar por múltiplos centros de custo e/ou subunidades
  # Quando sub_unit_id está presente, prioriza empenhos vinculados a essa subunidade
  # + empenhos do centro de custo que NÃO estão vinculados a nenhuma subunidade específica
  scope :by_cost_center_or_sub_unit_ids, lambda { |cost_center_ids, sub_unit_ids|
    cost_center_ids = Array(cost_center_ids).compact
    sub_unit_ids = Array(sub_unit_ids).compact
    
    if cost_center_ids.present? && sub_unit_ids.present?
      # Quando temos ambos: mostra empenhos da subunidade específica
      # + empenhos do centro de custo que NÃO estão vinculados a nenhuma subunidade
      joins("LEFT JOIN commitment_cost_centers ON commitment_cost_centers.commitment_id = commitments.id")
        .where(
          "(commitments.sub_unit_id IN (:sub_unit_ids)) OR " \
          "((commitment_cost_centers.cost_center_id IN (:cost_center_ids) OR commitments.cost_center_id IN (:cost_center_ids)) AND (commitments.sub_unit_id IS NULL))",
          cost_center_ids: cost_center_ids, sub_unit_ids: sub_unit_ids
        )
        .distinct
    elsif cost_center_ids.present?
      joins("LEFT JOIN commitment_cost_centers ON commitment_cost_centers.commitment_id = commitments.id")
        .where("commitment_cost_centers.cost_center_id IN (:cost_center_ids) OR commitments.cost_center_id IN (:cost_center_ids)", cost_center_ids: cost_center_ids)
        .distinct
    elsif sub_unit_ids.present?
      where(sub_unit_id: sub_unit_ids)
    else
      none
    end
  }

  scope :by_active, lambda { |value| where("commitments.active = ?", value) if !value.nil? && value != "" }
  scope :by_category_id, lambda { |value| where("commitments.category_id = ?", value) if !value.nil? && !value.blank? }

  belongs_to :client, :class_name => 'User', foreign_key: 'client_id', optional: true
  belongs_to :cost_center, optional: true # Mantido para compatibilidade, mas usar cost_centers para múltiplos
  belongs_to :contract, optional: true
  belongs_to :sub_unit, optional: true
  belongs_to :category, optional: true

  # Relacionamento N:N com centros de custo (múltiplos)
  has_many :commitment_cost_centers, dependent: :destroy
  has_many :cost_centers, through: :commitment_cost_centers

  has_many :order_services, dependent: :destroy
  has_many :order_services_parts, class_name: 'OrderService', foreign_key: 'commitment_parts_id'
  has_many :order_services_services, class_name: 'OrderService', foreign_key: 'commitment_services_id'

  has_many :cancel_commitments, validate: false, dependent: :destroy
  accepts_nested_attributes_for :cancel_commitments, reject_if: ->(attributes){ attributes['number'].blank? }, allow_destroy: true

  has_many :addendum_commitments, dependent: :destroy
  accepts_nested_attributes_for :addendum_commitments, reject_if: ->(attributes){ attributes['number'].blank? }, allow_destroy: true

  validates_presence_of :client_id
  # category_id pode ser nil para empenhos "Global" (Peças e Serviços)
  validates :contract_id, :commitment_number, :commitment_value, presence: true, if: Proc.new { |a| a.skip_validations.nil? }
  validate :validate_at_least_one_cost_center, if: Proc.new { |a| a.skip_validations.nil? }

  def validate_at_least_one_cost_center
    if cost_center_ids.blank? && cost_center_id.blank?
      errors.add(:cost_center_ids, "deve selecionar pelo menos um centro de custo")
    end
  end

  validate :validate_commitent_value, if: Proc.new { |a| a.skip_validations.nil? }

  def as_json(options = {})
		{
			:id => self.id,
			:created_at => self.created_at,
			:updated_at => self.updated_at,
			:commitment_number => self.commitment_number,
			:formatted_name => self.get_formatted_name_with_pendent_value
		}
	end

  def get_text_name
    # Prioriza os múltiplos centros de custo (nova estrutura)
    if self.cost_centers.any?
      cost_center_names = self.cost_centers.map(&:get_text_name).join(', ')
      cost_center_names + ' / ' + self.commitment_number.to_s
    elsif self.cost_center.present?
      # Fallback para compatibilidade com registros antigos
      self.cost_center.get_text_name + ' / ' + self.commitment_number.to_s
    else
      self.commitment_number.to_s
    end
  end

  def commitment_value=(new_commitment_value)
		self[:commitment_value] = CustomHelper.currency_to_value(new_commitment_value)
	end

  def canceled_value=(new_canceled_value)
		self[:canceled_value] = CustomHelper.currency_to_value(new_canceled_value)
	end

  def get_formatted_name
    self.get_text_name
  end

  def get_formatted_name_with_pendent_value
    values = Commitment.getting_values_to_commitment(self)
    self.get_text_name + ' - ' + CustomHelper.to_currency(values[:pendent_value])
  end

  def self.getting_data_by_user(current_user, client_id, cost_center_id = nil, sub_unit_id = nil)
    result = []
    
    # Base query: active commitments with value, for the client
    base_query = Commitment.where(active: true).where.not(commitment_value: [nil])
    
    # Inicializar commitments com valor padrão para evitar nil
    commitments = base_query.none
    
    if current_user.admin?
      # Admin vê todos os empenhos do cliente
      commitments = base_query.by_client_id(client_id)
      
      # Se um CC/SU específico foi passado, filtrar por ele
      if cost_center_id.present? || sub_unit_id.present?
        commitments = commitments.by_cost_center_or_sub_unit_ids([cost_center_id].compact, [sub_unit_id].compact)
      end
      
    elsif current_user.client?
      # Cliente vê seus próprios empenhos
      commitments = base_query.by_client_id(current_user.id)
      
      # Se um CC/SU específico foi passado, filtrar por ele
      if cost_center_id.present? || sub_unit_id.present?
        commitments = commitments.by_cost_center_or_sub_unit_ids([cost_center_id].compact, [sub_unit_id].compact)
      end
      
    elsif current_user.manager?
      # Gerente vê empenhos do seu cliente
      commitments = base_query.by_client_id(current_user.client_id)
      
      # Se um CC/SU específico foi passado, filtrar por ele
      if cost_center_id.present? || sub_unit_id.present?
        commitments = commitments.by_cost_center_or_sub_unit_ids([cost_center_id].compact, [sub_unit_id].compact)
      end
      
    elsif current_user.additional?
      # Usuário adicional: usar o CC/SU específico do veículo
      # Mas validar se o usuário tem acesso àquele CC/SU
      authorized_cost_center_ids = current_user.associated_cost_centers.map(&:id)
      authorized_sub_unit_ids = current_user.associated_sub_units.map(&:id)
      
      commitments = base_query.by_client_id(current_user.client_id)
      
      # Usar o CC/SU do veículo, se foi passado
      if cost_center_id.present? || sub_unit_id.present?
        # Validar se o usuário tem acesso ao CC/SU do veículo
        can_access = false
        
        if cost_center_id.present? && authorized_cost_center_ids.include?(cost_center_id)
          can_access = true
        end
        
        if sub_unit_id.present? && authorized_sub_unit_ids.include?(sub_unit_id)
          can_access = true
        end
        
        if can_access
          # Filtrar pelos empenhos do CC/SU do veículo
          commitments = commitments.by_cost_center_or_sub_unit_ids([cost_center_id].compact, [sub_unit_id].compact)
        else
          # Usuário não tem acesso ao CC/SU do veículo
          commitments = commitments.none
        end
      else
        # Se nenhum veículo foi selecionado, mostrar empenhos de todos os CCs/SUs autorizados
        commitments = commitments.by_cost_center_or_sub_unit_ids(authorized_cost_center_ids, authorized_sub_unit_ids)
      end
    end
    
    commitments = commitments.order('commitments.commitment_number').uniq
    
    commitments.each do |commitment|
      values = Commitment.getting_values_to_commitment(commitment)
      if values[:pendent_value] > 0
        result.push(commitment)
      end
    end
    
    return result
  end

  def self.get_total_already_consumed_value(commitment)
    required_order_service_statuses = OrderServiceStatus::REQUIRED_ORDER_SERVICE_STATUSES
    required_proposal_statuses = OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES

    return 0 if commitment.nil?
    
    # Se o empenho é GLOBAL (category_id nil), somar tudo
    if commitment.category_id.nil?
      order_services = OrderService.where(commitment_id: commitment.id)
                                  .where(order_service_status_id: required_order_service_statuses)
      
      total = order_services.joins(:order_service_proposals)
                          .where(order_service_proposals: { 
                            order_service_proposal_status_id: required_proposal_statuses,
                            is_complement: [false, nil]  # Evitar duplicar complementos
                          })
                          .sum("order_service_proposals.total_value")
      
      return total
    end
    
    # Se o empenho tem categoria, calcular consumo específico por tipo.
    # Usar total_value dos itens (COM desconto aplicado) para calcular o consumo real
    if commitment.category_id == Category::SERVICOS_PECAS_ID
      return OrderServiceProposalItem
        .joins(:service)
        .joins(order_service_proposal: :order_service)
        .where(order_services: { commitment_parts_id: commitment.id, order_service_status_id: required_order_service_statuses })
        .where(order_service_proposals: { order_service_proposal_status_id: required_proposal_statuses, is_complement: [false, nil] })
        .where(services: { category_id: Category::SERVICOS_PECAS_ID })
        .sum('order_service_proposal_items.total_value')

    elsif commitment.category_id == Category::SERVICOS_SERVICOS_ID
      return OrderServiceProposalItem
        .joins(:service)
        .joins(order_service_proposal: :order_service)
        .where(order_services: { commitment_services_id: commitment.id, order_service_status_id: required_order_service_statuses })
        .where(order_service_proposals: { order_service_proposal_status_id: required_proposal_statuses, is_complement: [false, nil] })
        .where(services: { category_id: Category::SERVICOS_SERVICOS_ID })
        .sum('order_service_proposal_items.total_value')
    end
    
    # Fallback: se categoria desconhecida
    return 0
  end

  def self.getting_values_to_commitment(commitment)
    total_already_consumed_value = Commitment.get_total_already_consumed_value(commitment)
    sum_budget_value = Commitment.sum_budget_value(commitment)
    pendent_value = (sum_budget_value - total_already_consumed_value).to_f
    {
      total_already_consumed_value: total_already_consumed_value.to_f,
      sum_budget_value: sum_budget_value.to_f,
      pendent_value: pendent_value.to_f
    }
  end

  def get_available_balance
    # Retorna o saldo disponível deste empenho (commitment_value - já consumido)
    values = Commitment.getting_values_to_commitment(self)
    values[:pendent_value]
  end

  def self.sum_budget_value(commitment)
    # Commitment value + Addendum values - Cancel commitment value
    return 0 if commitment.nil?
    commitment_value = commitment.commitment_value.to_f
    addendum_value = commitment.addendum_commitments.where(active: true).sum(:total_value).to_f
    cancel_commitment_value = commitment.cancel_commitments.sum('cancel_commitments.value').to_f
    result = commitment_value + addendum_value - cancel_commitment_value
    return result
  end

  private

  def default_values
    self.commitment_number ||= ''
    self.canceled_value ||= 0
    self.active = true if self.active.nil?
  end

  def validate_commitent_value
    return if self.contract_id.blank?
    disponible_value = self.contract.get_disponible_value(self.id)
    if disponible_value < self.commitment_value.to_f
      errors.add(:commitment_value, "não pode ser maior que o valor disponível.")
    end
  end


end
