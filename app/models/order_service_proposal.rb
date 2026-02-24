class OrderServiceProposal < ApplicationRecord
  audited
  after_initialize :default_values
  after_create :generate_code
  before_update :set_warranty_start_date_on_authorization
  after_update :sync_order_service_status, if: :saved_change_to_order_service_proposal_status_id?

  attr_accessor :files, :skip_validation

  # audited only: [:order_service_proposal_status_id], on: [:create, :update]

  default_scope {
    order({order_service_proposal_status_id: :asc}, {created_at: :desc})
  }

  scope :by_id, lambda { |value| where("order_service_proposals.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_provider_id, lambda { |value| where("order_service_proposals.provider_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_client_id, lambda { |value| joins(:order_service).where("order_services.client_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_order_service_id, lambda { |value| where("order_service_proposals.order_service_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_order_services_id, lambda { |values| where("order_service_proposals.order_service_id IN (?)", values) }
  scope :by_order_service_proposal_status_id, lambda { |value| where("order_service_proposals.order_service_proposal_status_id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(order_service_proposals.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  scope :by_code, lambda { |value| where("LOWER(order_service_proposals.code) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("order_service_proposals.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("order_service_proposals.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

  scope :by_initial_total_value, lambda { |value| where("order_service_proposals.total_value >= ?", value) if !value.nil? && !value.blank? }
  scope :by_final_total_value, lambda { |value| where("order_service_proposals.total_value <= ?", value) if !value.nil? && !value.blank? }

  scope :by_initial_total_discount, lambda { |value| where("order_service_proposals.total_discount >= ?", value) if !value.nil? && !value.blank? }
  scope :by_final_total_discount, lambda { |value| where("order_service_proposals.total_discount <= ?", value) if !value.nil? && !value.blank? }

  # Scopes para fluxo de aprovação em duas etapas
  scope :pending_manager_approval, -> { where(pending_manager_approval: true) }
  scope :pending_manager_authorization, -> { where(pending_manager_authorization: true) }
  scope :pending_manager_action, -> { where("pending_manager_approval = ? OR pending_manager_authorization = ?", true, true) }
  scope :complement_proposals, -> { where(is_complement: true) }
  scope :not_complement, -> { where(is_complement: [false, nil]) }

  belongs_to :order_service, optional: true
  belongs_to :provider, :class_name => 'User', optional: true
  belongs_to :order_service_proposal_status, optional: true
  belongs_to :approved_by_additional, :class_name => 'User', optional: true
  belongs_to :authorized_by_additional, :class_name => 'User', optional: true
  belongs_to :refused_by_manager, :class_name => 'User', foreign_key: 'refused_by_manager_id', optional: true
  belongs_to :parent_proposal, class_name: 'OrderServiceProposal', optional: true
  
  has_many :complement_proposals, class_name: 'OrderServiceProposal', foreign_key: 'parent_proposal_id', dependent: :nullify

  has_many :order_service_proposal_items, validate: false, dependent: :destroy
  accepts_nested_attributes_for :order_service_proposal_items, :reject_if  => proc { |attrs| attrs[:service_id].blank? }

  has_many :provider_service_temps, inverse_of: :order_service_proposal, validate: true, dependent: :destroy
  accepts_nested_attributes_for :provider_service_temps, 
    reject_if: proc { |attrs| attrs[:service_id].blank? && attrs[:name].blank? },
    allow_destroy: true

  has_many :order_service_invoices, validate: true, dependent: :destroy
  accepts_nested_attributes_for :order_service_invoices, :reject_if  => proc { |attrs| attrs[:number].blank? || attrs[:value].blank? }

  has_many :attachments, as: :ownertable, validate: false, dependent: :destroy
	accepts_nested_attributes_for :attachments, :reject_if => :all_blank

  validates_presence_of :order_service_id, :provider_id, :order_service_proposal_status_id, if: Proc.new { |obj| obj.skip_validation != true }

  def get_text_name
    self.id.to_s
  end

  def self.getting_total_order_services_proposal_by_status(current_user, order_service_proposal_status_id)
    scoped = OrderServiceProposal
      .unscoped
      .where(is_complement: [false, nil])
      .by_provider_id(current_user.id)

    # Para fornecedor, o status "Aguardando Aprovação de Complemento" não deve contar o registro
    # do complemento (is_complement=true), e sim a proposta PAI aprovada cuja OS tem complemento pendente.
    if order_service_proposal_status_id.to_i == OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
      pending_order_service_ids = OrderServiceProposal
        .unscoped
        .where(
          is_complement: true,
          provider_id: current_user.id,
          order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
        )
        .select(:order_service_id)

      return scoped
        .by_order_service_proposal_status_id(OrderServiceProposalStatus::APROVADA_ID)
        .where(order_service_id: pending_order_service_ids)
        .distinct
        .count(:id)
    end

    # Evita que OS com complemento pendente apareçam também em "Aprovada" (senão gera duplicidade visual)
    if order_service_proposal_status_id.to_i == OrderServiceProposalStatus::APROVADA_ID
      pending_order_service_ids = OrderServiceProposal
        .unscoped
        .where(
          is_complement: true,
          provider_id: current_user.id,
          order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
        )
        .select(:order_service_id)

      scoped = scoped.where.not(order_service_id: pending_order_service_ids)
    end

    scoped
      .by_order_service_proposal_status_id(order_service_proposal_status_id)
      .distinct
      .count(:id)
  end

  # Retorna o total_value calculado incluindo complementos aprovados
  # Útil para exibição onde o valor armazenado pode estar desatualizado
  def total_value_with_complements
    return total_value.to_f if is_complement
    
    # Valor base da proposta principal
    base_total = total_value.to_f
    
    # Somar valores dos complementos aprovados (que têm status nos REQUIRED_PROPOSAL_STATUSES)
    approved_complements = complement_proposals
      .where(order_service_proposal_status_id: OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES)
    
    complement_total = approved_complements.sum(:total_value).to_f
    
    base_total + complement_total
  end

  def self.update_total_values(order_service_proposal)
    values = calculate_total_values(order_service_proposal)
    order_service_proposal.update_columns(values)
  end

  # Garante que os totais persistidos batem com os itens atuais.
  # Atualiza somente quando detectar divergência (evita writes desnecessários).
  def self.ensure_total_values(order_service_proposal)
    values = calculate_total_values(order_service_proposal)

    current_discount = order_service_proposal.total_discount.to_d.round(2)
    current_without_discount = order_service_proposal.total_value_without_discount.to_d.round(2)
    current_total = order_service_proposal.total_value.to_d.round(2)

    if current_discount != values[:total_discount] ||
       current_without_discount != values[:total_value_without_discount] ||
       current_total != values[:total_value]
      order_service_proposal.update_columns(values)
      # Importante: update_columns não atualiza atributos do objeto em memória.
      # Precisamos manter o objeto coerente para a mesma request (ex.: grid/listagem).
      order_service_proposal.assign_attributes(values)
    end

    values
  end

  def self.calculate_total_values(order_service_proposal)
    items = items_for_totals(order_service_proposal)

    total_discount = items.sum { |i| i.discount.to_d }
    total_value_without_discount = items.sum do |i|
      base = (i.unity_value.to_d * i.quantity.to_d)
      stored = i.total_value_without_discount
      stored = nil if stored.present? && stored.to_d.zero? && base.positive?
      stored.present? ? stored.to_d : base
    end
    total_value = items.sum do |i|
      base_without_discount = (i.unity_value.to_d * i.quantity.to_d)
      stored_without_discount = i.total_value_without_discount
      stored_without_discount = nil if stored_without_discount.present? && stored_without_discount.to_d.zero? && base_without_discount.positive?
      effective_without_discount = stored_without_discount.present? ? stored_without_discount.to_d : base_without_discount

      stored_total = i.total_value
      stored_total = nil if stored_total.present? && stored_total.to_d.zero? && effective_without_discount.positive?
      stored_total.present? ? stored_total.to_d : (effective_without_discount - i.discount.to_d)
    end

    {
      total_discount: total_discount.round(2),
      total_value_without_discount: total_value_without_discount.round(2),
      total_value: total_value.round(2)
    }
  end

  # Itens usados para calcular totais exibidos/armazenados.
  # Regra: proposta principal soma seus itens + itens de complementos aprovados,
  # mas evita duplicar quando o merge já copiou itens para a proposta pai.
  def self.items_for_totals(order_service_proposal)
    all_items = order_service_proposal.order_service_proposal_items.includes(:service).to_a

    return all_items if order_service_proposal.is_complement

    merged_signatures = {}
    all_items
      .select { |i| i.is_complement }
      .each do |i|
        sig = [i.service_id, i.quantity.to_i, i.unity_value.to_f, i.discount.to_f, i.total_value.to_f, i.total_value_without_discount.to_f, i.brand.to_s, i.warranty_period.to_i]
        merged_signatures[sig] = true
      end

    approved_complement_ids = order_service_proposal.complement_proposals
      .where(order_service_proposal_status_id: OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES)
      .pluck(:id)

    return all_items unless approved_complement_ids.any?

    complement_items = OrderServiceProposalItem
      .includes(:service)
      .where(order_service_proposal_id: approved_complement_ids)
      .to_a

    complement_items.each do |ci|
      sig = [ci.service_id, ci.quantity.to_i, ci.unity_value.to_f, ci.discount.to_f, ci.total_value.to_f, ci.total_value_without_discount.to_f, ci.brand.to_s, ci.warranty_period.to_i]
      next if merged_signatures[sig]
      all_items << ci
    end

    all_items
  end

  def audit_creation(user)
    current_status_name = OrderServiceProposalStatus.find_by(id: self.order_service_proposal_status_id)&.name || "Unknown Status"
    audits.last.update!(
      user: user,
      action: 'create',
      audited_changes: {
        "order_service_proposal_status" => ["-", current_status_name],
        "order_service_proposal_status_id" => ["-", self.order_service_proposal_status_id]
      }
    )
  end

  def self.generate_historic(order_service_proposal, current_user, old_order_service_proposal_status_id, new_order_service_proposal_status_id)
    old_status_name = OrderServiceProposalStatus.find_by(id: old_order_service_proposal_status_id)&.name || "Unknown Status"
    new_status_name = OrderServiceProposalStatus.find_by(id: new_order_service_proposal_status_id)&.name || "Unknown Status"

    order_service_proposal.audits.create!(
      user: current_user,
      action: 'update',
      audited_changes: {
        "order_service_proposal_status" => [old_status_name, new_status_name],
        "order_service_proposal_status_id" => [old_order_service_proposal_status_id, new_order_service_proposal_status_id]
      }
    )
  end

  def getting_badge_color_by_status(order_service_proposal_status_id)
    case order_service_proposal_status_id
    when OrderServiceProposalStatus::EM_ABERTO_ID
      return 'bg-ligth text-black'
    when OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID
      return 'bg-info text-white'
    when OrderServiceProposalStatus::APROVADA_ID
      return 'bg-secondary'
    when OrderServiceProposalStatus::NOTAS_INSERIDAS_ID
      return 'bg-warning text-black'
    when OrderServiceProposalStatus::AUTORIZADA_ID
      return 'bg-primary'
    when OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID
      return 'bg-warning text-black'
    when OrderServiceProposalStatus::PAGA_ID
      return 'bg-success'
    when OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID
      return 'bg-danger text-white'
    when OrderServiceProposalStatus::CANCELADA_ID
      return 'bg-danger'
    else
      return 'text-black'
    end
  end

  def can_manage_by_pendent_value
    commitment = self.order_service.commitment
    values = Commitment.getting_values_to_commitment(commitment)
    return (values[:pendent_value] >= self.total_value)
  end

  def approval_justification_triggers
    # 🎯 Justificativa obrigatória APENAS para itens com preço acima da tabela de referência
    vehicle_id = order_service&.vehicle_id
    return [] if vehicle_id.blank?

    order_service_proposal_items
      .select { |item| item.get_category_id == Category::SERVICOS_PECAS_ID }
      .map do |item|
        price_check = item.price_vs_reference
        
        next unless price_check[:exceeded]
        
        {
          service_name: item.service_name.presence || item.service&.name,
          exceeded: true,
          percentage: price_check[:percentage],
          reference_price: price_check[:reference_price],
          max_allowed: price_check[:max_allowed],
          current_price: price_check[:current_price]
        }
      end
      .compact
  end

  def requires_approval_justification?
    approval_justification_triggers.any?
  end

  private

  def generate_code
    result = ""
    # Formata ID com 4 dígitos (0001, 0002, etc)
    id = self.id.to_s.rjust(4, '0')
    order_service_code = self.order_service.code
    result = 'P'+id+order_service_code
    self.update_columns(code: result)
  end

  def default_values
    self.details ||= ""
    self.order_service_proposal_status_id ||= OrderServiceProposalStatus::EM_CADASTRO_ID
  end

  def set_warranty_start_date_on_authorization
    # Quando o status mudar para Autorizada, define a data de início da garantia
    if order_service_proposal_status_id_changed? && 
       order_service_proposal_status_id == OrderServiceProposalStatus::AUTORIZADA_ID
      
      warranty_start = Time.zone.today
      
      # Atualizar todos os itens desta proposta que ainda não têm data de início
      order_service_proposal_items.each do |item|
        if item.warranty_period.present? && item.warranty_period > 0 && item.warranty_start_date.blank?
          item.update_column(:warranty_start_date, warranty_start)
        end
      end
    end
  end

  # Sincroniza automaticamente o status da OS quando o status da proposta mudar
  def sync_order_service_status
    return if order_service.nil?
    return if is_complement? # Complementos não alteram status da OS principal
    
    # Mapeamento automático: Status da Proposta → Status da OS
    status_mapping = {
      OrderServiceProposalStatus::APROVADA_ID => OrderServiceStatus::APROVADA_ID,
      OrderServiceProposalStatus::NOTAS_INSERIDAS_ID => OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID,
      OrderServiceProposalStatus::AUTORIZADA_ID => OrderServiceStatus::AUTORIZADA_ID,
      OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID => OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID,
      OrderServiceProposalStatus::PAGA_ID => OrderServiceStatus::PAGA_ID
    }
    
    new_os_status = status_mapping[order_service_proposal_status_id]
    
    # Se há mapeamento e o status da OS está diferente, atualizar
    if new_os_status.present? && order_service.order_service_status_id != new_os_status
      old_status = order_service.order_service_status_id
      
      # Atualizar status da OS
      OrderService.where(id: order_service.id).update_all(order_service_status_id: new_os_status)
      
      # Gerar histórico se possível
      begin
        admin_user = User.find_by(profile_id: 1) || User.first
        OrderService.generate_historic(order_service, admin_user, old_status, new_os_status) if admin_user
      rescue => e
        Rails.logger.warn "Não foi possível gerar histórico para OS #{order_service.id}: #{e.message}"
      end
      
      Rails.logger.info "✓ Status da OS ##{order_service.id} sincronizado automaticamente: #{old_status} → #{new_os_status}"
    end
  end

end
