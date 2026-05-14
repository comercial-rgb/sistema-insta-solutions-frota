class OrderService < ApplicationRecord
  # audited
  paginates_per 50
  after_initialize :default_values
  after_create :generate_code
  attr_accessor :files

  # ActiveStorage attachments for vehicle photos
  has_many_attached :vehicle_photos
  validates :vehicle_photos, safe_file: { profile: :media }, if: -> { vehicle_photos.attached? }

  # Constantes para origin_type
  ORIGIN_DIAGNOSTICO_DIAGNOSTICO = 'diagnostico_diagnostico'
  ORIGIN_DIAGNOSTICO_COTACOES = 'diagnostico_cotacoes'

  audited except: [
    :invoice_part_ir, :invoice_part_pis, :invoice_part_cofins,
    :invoice_part_csll, :invoice_service_ir, :invoice_service_pis,
    :invoice_service_cofins, :invoice_service_csll], on: [:create, :update]

  default_scope {
    includes(
      :client,
      :order_service_status,
      :vehicle,
      :provider_service_type,
      :maintenance_plan,
      :order_service_type,
      :provider,
      :order_service_proposals
    ).order(:order_service_status_id, {updated_at: :desc})
  }

  scope :by_id, lambda { |value| where("order_services.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_data_inserted_by_provider, lambda { |value| where("order_services.data_inserted_by_provider = ?", value) if !value.nil? && !value.blank? }
  scope :by_release_quotation, lambda { |value| where("order_services.release_quotation = ?", value) if !value.nil? && !value.blank? }
  scope :by_client_id, lambda { |value| where("order_services.client_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_commitment_id, lambda { |value| where("order_services.commitment_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_sub_unit_id, lambda { |value| joins(:vehicle).where("vehicles.sub_unit_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_manager_id, lambda { |value| where("order_services.manager_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_code, lambda { |value| where("LOWER(order_services.code) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_provider_service_type_id, lambda { |value| where("order_services.provider_service_type_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_provider_service_types_id, lambda { |value| where("order_services.provider_service_type_id IN (?)", value) }
  scope :by_cost_center_id, lambda { |value| joins(:vehicle).where("vehicles.cost_center_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_cost_center_ids, lambda { |value| joins(:vehicle).where("vehicles.cost_center_id IN (?)", value) if !value.nil? }
  scope :by_vehicle_id, lambda { |value| where("order_services.vehicle_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_order_service_type_id, lambda { |value| where("order_services.order_service_type_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_order_service_status_id, lambda { |value| where("order_services.order_service_status_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_order_service_statuses_id, lambda { |value| where("order_services.order_service_status_id IN (?)", value) if !value.nil? }

  scope :by_order_service_proposal_status_id, lambda { |value| joins(:order_service_proposals).where("order_service_proposals.order_service_proposal_status_id = ?", value) if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("order_services.created_at >= '#{value} 00:00:00'") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("order_services.created_at <= '#{value} 23:59:59'") if !value.nil? && !value.blank? }

  scope :by_initial_updated_at, lambda { |value| where("order_services.updated_at >= '#{value} 00:00:00'") if !value.nil? && !value.blank? }
  scope :by_final_updated_at, lambda { |value| where("order_services.updated_at <= '#{value} 23:59:59'") if !value.nil? && !value.blank? }

  # Scopes para precificação Cilia
  scope :cilia_pending, -> { where(cilia_priced_at: nil) }
  scope :cilia_completed, -> { where.not(cilia_priced_at: nil) }

  # Scopes para faturamento
  scope :not_invoiced, -> { where(invoiced: false) }
  scope :invoiced_only, -> { where(invoiced: true) }

  # Scope para buscar OSs que ENTRARAM no status AUTORIZADA no período (usando histórico do Audited)
  scope :approved_in_period, lambda { |start_date, end_date|
    if start_date.present? && end_date.present?
      start_time = Date.parse(start_date.to_s).beginning_of_day
      end_time = Date.parse(end_date.to_s).end_of_day

      # IMPORTANTE: usar associated_id (novo status) para pegar ENTRADA no status,
      # e não confundir com SAÍDA (onde AUTORIZADA aparece como status antigo no audited_changes).
      # Usa APENAS AUTORIZADA_ID (5). O NEW_AUTORIZADA_ID (7) NÃO deve ser usado pois
      # no banco de produção 7 = Paga, e incluí-lo faz aparecer OSs de outros meses.
      
      left_outer_joins(:audits)
        .where(audits: { auditable_type: 'OrderService' })
        .where(audits: { associated_id: OrderServiceStatus::AUTORIZADA_ID })
        .where(audits: { created_at: start_time..end_time })
        .distinct
    end
  }

  scope :by_state_id, lambda { |value|
    joins(client: :states)
    .where("states.id IN (?)", value) if !value.nil? && !value.blank?
  }

  scope :by_proposal_provider_id, lambda { |value|
    left_outer_joins(:order_service_proposals)
      .where(
        "(order_service_proposals.provider_id = ? AND order_service_proposals.order_service_proposal_status_id IN (?)) OR order_services.provider_id = ?",
        value, OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES, value
      )
      .distinct
  }

  # Exclui OSs onde o fornecedor já tem proposta ativa (não cancelada/reprovada)
  scope :excluded_by_active_proposal_by_provider, lambda { |current_user_id|
    where('NOT EXISTS (
      SELECT 1 FROM order_service_proposals osp 
      WHERE osp.order_service_id = order_services.id 
      AND osp.provider_id = ? 
      AND osp.order_service_proposal_status_id NOT IN (?)
    )', current_user_id, [
            OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
            OrderServiceProposalStatus::CANCELADA_ID
          ])
  }

  scope :with_user_relation, lambda { |current_user_id|
    left_outer_joins(:order_service_proposals, :rejected_providers)
      .where(
        'order_service_proposals.provider_id = :user_id OR rejected_order_services_providers.provider_id = :user_id',
        user_id: current_user_id
      ).distinct
  }

  # Scope para relatórios: mostra apenas OSs onde o fornecedor tem propostas (exclui rejected)
  scope :with_provider_proposals_only, lambda { |provider_id|
    joins(:order_service_proposals)
      .where('order_service_proposals.provider_id = ?', provider_id)
      .distinct
  }

  scope :by_provider_id_or_null, lambda { |value|
    if value.present?
      where(
        "(order_services.provider_id IS NULL OR order_services.provider_id = ? OR (order_services.provider_id != ? AND order_services.release_quotation = ?))",
        value, value, true
      )
    end
  }
  
  # Scope específico para fornecedores verem OSs disponíveis
  # Inclui: OSs sem fornecedor, OSs atribuídas a ele, e OSs de outros com release_quotation
  scope :visible_by_provider, lambda { |provider_id|
    if provider_id.present?
      where(
        "(order_services.provider_id IS NULL OR order_services.provider_id = ?)",
        provider_id
      )
    end
  }

  scope :approved_in_current_month, lambda { |filter, current_month|
    if filter && current_month
      # REGRA DE NEGÓCIO: Pega OSs que foram AUTORIZADAS no período selecionado.
      # Usa o campo associated_id dos audits, que é preenchido pelo generate_historic
      # com o novo status ID quando a OS muda de status.
      # Usa APENAS AUTORIZADA_ID (5). O NEW_AUTORIZADA_ID (7) NÃO deve ser usado pois
      # no banco de produção 7 = Paga, e incluí-lo faz aparecer OSs de outros meses.
      
      start_time = current_month.first.to_date.beginning_of_day
      end_time = current_month.last.to_date.end_of_day
      
      left_outer_joins(:audits)
        .where(audits: { auditable_type: 'OrderService' })
        .where(audits: { associated_id: OrderServiceStatus::AUTORIZADA_ID })
        .where(audits: { created_at: start_time..end_time })
        .distinct
    end
  }

  scope :reached_status_in_period, lambda { |status_id, date_range|
    if status_id.present? && date_range.present?
      # Busca OSs que ESTÃO no status especificado E atingiram esse status no período
      # Garante que a OS não apareça em aba errada
      left_outer_joins(:audits)
        .where(order_service_status_id: status_id)
        .where(audits: { auditable_type: 'OrderService' })
        .where(audits: { associated_id: status_id })
        .where(audits: { created_at: date_range })
        .distinct
    end
  }
  
  scope :in_statuses_reached_in_period, lambda { |status_ids, target_status_id, date_range|
    if status_ids.present? && target_status_id.present? && date_range.present?
      # Para abas com múltiplos status (ex: Autorizadas, Nota Fiscal, Paga)
      # Mostra OSs que estão em qualquer dos status permitidos E passaram pelo status alvo no período
      left_outer_joins(:audits)
        .where(order_service_status_id: status_ids)
        .where(audits: { auditable_type: 'OrderService' })
        .where(audits: { associated_id: target_status_id })
        .where(audits: { created_at: date_range })
        .distinct
    end
  }

  scope :by_cost_center_or_sub_unit_ids, lambda { |cost_center_ids, sub_unit_ids|
    joins(:vehicle).where(
      "vehicles.cost_center_id IN (:cost_center_ids) OR vehicles.sub_unit_id IN (:sub_unit_ids)",
      cost_center_ids: cost_center_ids, sub_unit_ids: sub_unit_ids
    ) if cost_center_ids.present? || sub_unit_ids.present?
  }

  belongs_to :order_service_status, optional: true
  belongs_to :client, :class_name => 'User', optional: true
  belongs_to :vehicle, optional: true
  belongs_to :provider_service_type, optional: true
  belongs_to :maintenance_plan, optional: true
  belongs_to :order_service_type, optional: true
  belongs_to :provider, :class_name => 'User', optional: true
  belongs_to :manager, :class_name => 'User', optional: true
  belongs_to :commitment, optional: true
  
  # Novas associações para empenhos separados por categoria
  belongs_to :commitment_parts, class_name: 'Commitment', foreign_key: 'commitment_parts_id', optional: true
  belongs_to :commitment_services, class_name: 'Commitment', foreign_key: 'commitment_services_id', optional: true

  # Associação com ServiceGroup para tipo Requisição
  belongs_to :service_group, optional: true
  
  # Usuário que solicitou reavaliação
  belongs_to :reevaluation_requested_by, class_name: 'User', optional: true

  # Precificação Cilia
  belongs_to :cilia_priced_by, class_name: 'User', optional: true

  has_one :cost_center, :through => :vehicle

  has_one :sub_unit, :through => :vehicle

  has_many :attachments, as: :ownertable, validate: false, dependent: :destroy
	accepts_nested_attributes_for :attachments, :reject_if => :all_blank

  has_many :order_service_proposals, validate: false, dependent: :destroy
	accepts_nested_attributes_for :order_service_proposals

  has_one :webhook_log, dependent: :destroy

  has_many :part_service_order_services, validate: false, dependent: :destroy
	accepts_nested_attributes_for :part_service_order_services, 
    reject_if: proc { |attrs| attrs[:service_id].blank? },
    allow_destroy: true

  has_many :stock_order_service_items, validate: false, dependent: :destroy
  accepts_nested_attributes_for :stock_order_service_items,
    reject_if: proc { |attrs| attrs[:stock_item_id].blank? },
    allow_destroy: true

  has_and_belongs_to_many :rejected_providers,
            class_name: 'User',
            join_table: :rejected_order_services_providers,
            association_foreign_key: :provider_id,
            foreign_key: :order_service_id

  has_and_belongs_to_many :directed_providers,
            class_name: 'User',
            join_table: :order_service_directed_providers,
            association_foreign_key: :provider_id,
            foreign_key: :order_service_id,
            validate: false

  validates_presence_of :client_id, :manager_id, :vehicle_id,
  :provider_service_type_id, :maintenance_plan_id,
  :order_service_type_id, :details, :order_service_status_id

  validates_presence_of :km, :if => Proc.new { |a| a.client && a.client.needs_km && a.new_record? }
  validate :validate_min_km, :if => Proc.new { |a| a.client && a.client.needs_km && a.km.present? && a.km_changed? }
  validate :validate_vehicle_photos, :if => Proc.new { |a| 
    # ⚠️ IMPORTANTE: Só valida fotos para OSs NOVAS quando o cliente exige
    # OSs antigas (já persistidas) não são validadas para não bloquear propostas
    a.new_record? && 
    a.client && 
    a.client.require_vehicle_photos
  }
  validate :validate_commitment_presence, :on => :create
  validate :validate_commitments_by_category
  validate :validate_service_group_for_requisicao
  validate :validate_services_in_service_group
  validate :validate_provider_for_diagnostico

	def as_json(options = {})
		{
			:id => self.id,
			:created_at => self.created_at,
			:updated_at => self.updated_at,
      :created_at_formatted => CustomHelper.get_text_date(self.created_at, 'datetime', :full),
			:updated_at_formatted => CustomHelper.get_text_date(self.updated_at, 'datetime', :full),
			:code => self.code,
			:km => self.km,
			:driver => self.driver,
			:details => self.details,
			:order_service_status => self.order_service_status,
			:vehicle => self.vehicle,
			:provider_service_type => self.provider_service_type,
			:maintenance_plan => self.maintenance_plan,
			:order_service_type => self.order_service_type
		}
	end

  def get_text_name
    self.code.to_s
  end

	def invoice_part_ir=(new_invoice_part_ir)
		self[:invoice_part_ir] = CustomHelper.currency_to_value(new_invoice_part_ir)
	end

	def invoice_part_pis=(new_invoice_part_pis)
		self[:invoice_part_pis] = CustomHelper.currency_to_value(new_invoice_part_pis)
	end

	def invoice_part_cofins=(new_invoice_part_cofins)
		self[:invoice_part_cofins] = CustomHelper.currency_to_value(new_invoice_part_cofins)
	end

	def invoice_part_csll=(new_invoice_part_csll)
		self[:invoice_part_csll] = CustomHelper.currency_to_value(new_invoice_part_csll)
	end

	def invoice_service_ir=(new_invoice_service_ir)
		self[:invoice_service_ir] = CustomHelper.currency_to_value(new_invoice_service_ir)
	end

	def invoice_service_pis=(new_invoice_service_pis)
		self[:invoice_service_pis] = CustomHelper.currency_to_value(new_invoice_service_pis)
	end

	def invoice_service_cofins=(new_invoice_service_cofins)
		self[:invoice_service_cofins] = CustomHelper.currency_to_value(new_invoice_service_cofins)
	end

	def invoice_service_csll=(new_invoice_service_csll)
		self[:invoice_service_csll] = CustomHelper.currency_to_value(new_invoice_service_csll)
	end

  def self.getting_total_order_services_by_status(current_user, order_service_status_id)
    # Pseudo-status: OS APROVADAS com COMPLEMENTO pendente de aprovação
    if order_service_status_id.to_s == 'aguardando_complemento'
      scoped = OrderService
        .unscoped
        .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
        .joins(:order_service_proposals)
        .where(order_service_proposals: {
          is_complement: true,
          order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
        })

      if current_user.client?
        scoped = scoped.by_client_id(current_user.id)
      elsif current_user.manager? || current_user.additional?
        client_id = current_user.client_id
        cost_center_ids = current_user.associated_cost_centers.map(&:id)
        sub_unit_ids = current_user.associated_sub_units.map(&:id)
        scoped = scoped.by_client_id(client_id).by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
      end

      return scoped.distinct.count(:id)
    end

    if (current_user.admin? || current_user.client? || current_user.manager?) && order_service_status_id == OrderServiceStatus::TEMP_REJEITADA_ID
      return OrderService.unscoped.joins(:rejected_providers).distinct.count(:id)
    elsif current_user.admin?
      return OrderService.unscoped.by_order_service_status_id(order_service_status_id).count
    elsif current_user.client?
      return OrderService.unscoped.by_client_id(current_user.id).by_order_service_status_id(order_service_status_id).count
    elsif current_user.manager? || current_user.additional?
      client_id = current_user.client_id
      cost_center_ids = current_user.associated_cost_centers.map(&:id)
      sub_unit_ids = current_user.associated_sub_units.map(&:id)
      return OrderService.unscoped.by_client_id(client_id).by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids).by_order_service_status_id(order_service_status_id).count
    elsif current_user.provider?
      provider_state_id = -1
      if !current_user.address.nil? && !current_user.address.state.nil?
        provider_state_id = current_user.address.state_id
      end
      provider_service_types_ids = current_user.provider_service_types.map(&:id)

      if order_service_status_id == OrderServiceStatus::EM_ABERTO_ID
        rejected_ids = current_user.rejected_order_services.pluck(:id)
        statuses_to_filter = [OrderServiceStatus::EM_ABERTO_ID, OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID]
        cancelled_statuses = [OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID, OrderServiceProposalStatus::CANCELADA_ID]

        # Ramo 1 (sempre): OS direcionadas a este fornecedor
        directed_count = OrderService.unscoped
          .where(order_service_status_id: statuses_to_filter)
          .where.not(id: rejected_ids)
          .where(
            "EXISTS (SELECT 1 FROM order_service_directed_providers osdp WHERE osdp.order_service_id = order_services.id AND osdp.provider_id = ?)",
            current_user.id
          )
          .excluded_by_active_proposal_by_provider(current_user.id)
          .distinct.count(:id)

        # Ramo 2 (requer estado + tipo): OS abertas por estado
        state_count = 0
        if provider_state_id != -1 && provider_service_types_ids.present?
          state_count = OrderService.unscoped
            .where.not(id: rejected_ids)
            .by_state_id(provider_state_id)
            .by_provider_service_types_id(provider_service_types_ids)
            .by_provider_id_or_null(current_user.id)
            .by_order_service_statuses_id(statuses_to_filter)
            .excluded_by_active_proposal_by_provider(current_user.id)
            .where("order_services.directed_to_specific_providers = FALSE OR order_services.directed_to_specific_providers IS NULL")
            .distinct.count(:id)
        end

        return directed_count + state_count
      # Em reavaliação e Cancelada - fornecedor vê apenas OSs onde ele tem proposta
      elsif order_service_status_id == OrderServiceStatus::EM_REAVALIACAO_ID ||
            order_service_status_id == OrderServiceStatus::CANCELADA_ID
        return OrderService.unscoped
        .by_order_service_status_id(order_service_status_id)
        .with_user_relation(current_user.id)
        .distinct
        .count(:id)
      else
        return OrderService.unscoped
        .by_order_service_status_id(order_service_status_id)
        .with_user_relation(current_user.id)
        .distinct
        .count(:id)
      end
    end
  end

  def audit_creation(user)
    current_status_name = OrderServiceStatus.find_by(id: self.order_service_status_id)&.name || "Unknown Status"
    audits.last.update!(
      action: 'create',
      audited_changes: {
        "order_service_status" => ["-", current_status_name],
        "order_service_status_id" => ["-", self.order_service_status_id]
      },
      associated_id: self.order_service_status_id
    )
  end

  def self.generate_historic(order_service, current_user, old_order_service_status_id, new_order_service_status_id, &cancel_justification)
    old_status_name = OrderServiceStatus.find_by(id: old_order_service_status_id)&.name || "Unknown Status"
    new_status_name = OrderServiceStatus.find_by(id: new_order_service_status_id)&.name || "Unknown Status"

    order_service.audits.create!(
      user: current_user,
      action: 'update',
      audited_changes: {
        "order_service_status" => [old_status_name, new_status_name],
        "order_service_status_id" => [old_order_service_status_id, new_order_service_status_id]
      },
      associated_id: new_order_service_status_id
    )
  end

  def getting_badge_color_by_status(order_service_status_id)
    # IMPORTANTE: O sistema teve renumeração de IDs de status!
    # Suporta AMBOS os conjuntos de IDs (antigos e novos) para compatibilidade com histórico
    case order_service_status_id
    when 1, OrderServiceStatus::EM_ABERTO_ID  # Em aberto (antigo: 1, novo: 2)
      return 'bg-light text-black'
    when 2, OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID  # Aguardando avaliação (antigo: 2, novo: 4)
      return 'bg-info text-white'
    when 3, OrderServiceStatus::EM_REAVALIACAO_ID  # Em reavaliação (antigo: 3, novo: 3)
      return 'bg-warning text-dark'
    when OrderServiceStatus::APROVADA_ID  # Aprovada (novo: 5)
      return 'bg-secondary'
    when 4, OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID  # Nota fiscal inserida (antigo: 4, novo: 6)
      return 'bg-warning text-black'
    when 5, OrderServiceStatus::AUTORIZADA_ID  # Autorizada (antigo: 5, novo: 7)
      return 'bg-primary'
    when 6, OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID  # Aguardando pagamento (antigo: 6, novo: 8)
      return 'bg-warning text-black'
    when 7, OrderServiceStatus::PAGA_ID  # Paga (antigo: 7, novo: 9)
      return 'bg-success'
    when OrderServiceStatus::CANCELADA_ID  # Cancelada (novo: 10)
      return 'bg-danger'
    else
      return 'text-black'
    end
  end
  
  # Método para obter a cor do badge pelo NOME do status
  # Mais confiável que por ID devido à renumeração de IDs do sistema
  def self.getting_badge_color_by_status_name(status_name)
    return 'badge-secondary' if status_name.blank?
    
    # Normalizar o nome para comparação (lowercase, sem acentos)
    name = status_name.to_s.downcase
    
    # Usar include? para matching parcial (funciona com ou sem acentos corrompidos)
    if name.include?('cadastro')
      'bg-secondary text-white'
    elsif name.include?('aberto')
      'bg-light text-black'
    elsif name.include?('reavalia')
      'bg-warning text-dark'
    elsif name.include?('aguardando avalia') || name.include?('aguardando avalia')
      'bg-info text-white'
    elsif name.include?('aprovada')
      'bg-secondary'
    elsif name.include?('nota fiscal')
      'bg-warning text-black'
    elsif name.include?('autorizada')
      'bg-primary'
    elsif name.include?('aguardando pagamento')
      'bg-warning text-black'
    elsif name.include?('paga') && !name.include?('pagamento')
      'bg-success'
    elsif name.include?('cancelada')
      'bg-danger'
    else
      'badge-secondary'
    end
  end
  
  # Métodos para Reavaliação (Diagnóstico)
  def can_request_reevaluation?
    order_service_type_id == OrderServiceType::DIAGNOSTICO_ID &&
    order_service_status_id == OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID &&
    order_service_proposals.where.not(
      order_service_proposal_status_id: [
        OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
        OrderServiceProposalStatus::CANCELADA_ID
      ]
    ).count <= 1
  end
  
  def request_reevaluation!(user)
    return false unless can_request_reevaluation?
    
    old_status = order_service_status_id
    update!(
      order_service_status_id: OrderServiceStatus::EM_REAVALIACAO_ID,
      reevaluation_requested_at: Time.current,
      reevaluation_requested_by_id: user.id
    )
    OrderService.generate_historic(self, user, old_status, OrderServiceStatus::EM_REAVALIACAO_ID)

    # 🔧 Garantir que a proposta do fornecedor volte para edição (EM_CADASTRO)
    order_service_proposals
      .where(order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID)
      .find_each do |proposal|
        OrderServiceProposal.generate_historic(
          proposal,
          user,
          proposal.order_service_proposal_status_id,
          OrderServiceProposalStatus::EM_CADASTRO_ID
        )
        proposal.update_columns(order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID)
      end
    true
  end
  
  def in_reevaluation?
    order_service_status_id == OrderServiceStatus::EM_REAVALIACAO_ID
  end
  
  # Métodos para Complemento
  def can_add_complement?
    order_service_status_id == OrderServiceStatus::APROVADA_ID &&
    approved_proposal.present? &&
    [OrderServiceType::DIAGNOSTICO_ID, OrderServiceType::COTACOES_ID].include?(order_service_type_id)
  end
  
  def approved_proposal
    approved_statuses = [
      OrderServiceProposalStatus::APROVADA_ID,
      OrderServiceProposalStatus::NOTAS_INSERIDAS_ID,
      OrderServiceProposalStatus::AUTORIZADA_ID,
      OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
      OrderServiceProposalStatus::PAGA_ID
    ]

    # Quando a associação já está carregada em memória (ex: grid com includes),
    # filtra em Ruby para evitar N+1 por linha.
    if order_service_proposals.loaded?
      proposals = order_service_proposals.to_a
      main_candidates = proposals.select { |p| !p.is_complement && approved_statuses.include?(p.order_service_proposal_status_id) }
      main = if provider_id.present?
        main_candidates.select { |p| p.provider_id == provider_id }.max_by(&:updated_at) ||
        main_candidates.max_by(&:updated_at)
      else
        main_candidates.max_by(&:updated_at)
      end
      if main.present?
        OrderServiceProposal.ensure_total_values(main)
        return main
      end
      result = proposals.select { |p| approved_statuses.include?(p.order_service_proposal_status_id) }.max_by(&:updated_at)
      OrderServiceProposal.ensure_total_values(result) if result.present?
      return result
    end

    # Preferir a proposta principal (não complemento) e o fornecedor vinculado à OS.
    scope = order_service_proposals
      .where(is_complement: [false, nil])
      .where(order_service_proposal_status_id: approved_statuses)

    main =
      if provider_id.present?
        scope.where(provider_id: provider_id).order(updated_at: :desc).first
      end
    main ||= scope.order(updated_at: :desc).first
    if main.present?
      OrderServiceProposal.ensure_total_values(main)
      return main
    end

    # Fallback: comportamento legado (quando não existir proposta principal aprovada)
    result = order_service_proposals
      .where(order_service_proposal_status_id: approved_statuses)
      .order(updated_at: :desc)
      .first
    OrderServiceProposal.ensure_total_values(result) if result.present?
    result
  end

  # Lotes / transições: prioriza propostas do fornecedor vinculado à OS; se não houver, mantém +relation+ (legado).
  def proposals_scope_for_linked_provider(relation)
    return relation if provider_id.blank?

    filtered = relation.where(provider_id: provider_id)
    filtered.exists? ? filtered : relation
  end

  # OS já vinculada a um fornecedor: não avançar com proposta sem fornecedor ou de outro (concorrente).
  def locks_out_proposal?(proposal)
    return false if proposal.blank? || provider_id.blank?

    proposal.provider_id.blank? || proposal.provider_id != provider_id
  end
  
  # Verifica se tem propostas ativas (não canceladas/reprovadas)
  def has_active_proposals?
    order_service_proposals.where.not(
      order_service_proposal_status_id: [
        OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
        OrderServiceProposalStatus::CANCELADA_ID
      ]
    ).exists?
  end
  
  # Cancela todas as propostas ativas
  def cancel_all_proposals!(user, reason = "Peças/serviços da OS foram alterados")
    order_service_proposals.where.not(
      order_service_proposal_status_id: [
        OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
        OrderServiceProposalStatus::CANCELADA_ID
      ]
    ).find_each do |proposal|
      proposal.update!(
        order_service_proposal_status_id: OrderServiceProposalStatus::CANCELADA_ID,
        reason_reproved: reason
      )
    end
  end

  def getting_last_updated_data
    result = ''
    if self.audits.length > 0
      last_audit = self.audits.last
      result += CustomHelper.get_text_date(last_audit.created_at, 'datetime', :full)
      if !last_audit.user.nil?
        result += ' - '+last_audit.user.get_name
      end
    else
      result += CustomHelper.get_text_date(self.updated_at, 'datetime', :full)
      result += ' - '+self.manager.get_name
    end
    return result
  end

  def getting_order_service_proposal_approved
    return @_approved_proposal if defined?(@_approved_proposal)

    approved_statuses = [
      OrderServiceProposalStatus::APROVADA_ID,
      OrderServiceProposalStatus::NOTAS_INSERIDAS_ID,
      OrderServiceProposalStatus::AUTORIZADA_ID,
      OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
      OrderServiceProposalStatus::PAGA_ID
    ]

    # Quando a associação já está carregada em memória (ex: grid com includes),
    # filtra em Ruby para evitar N+1 por linha.
    if order_service_proposals.loaded?
      proposals = order_service_proposals.to_a
      result = proposals
        .select { |p| !p.is_complement && approved_statuses.include?(p.order_service_proposal_status_id) }
        .max_by(&:updated_at)
      result ||= proposals
        .select { |p| approved_statuses.include?(p.order_service_proposal_status_id) }
        .max_by(&:updated_at)
      OrderServiceProposal.ensure_total_values(result) if result.present?
      return @_approved_proposal = result
    end

    # Preferir a proposta principal para evitar que um complemento aprovado
    # seja tratado como a proposta "aprovada" principal.
    result = order_service_proposals
      .where(is_complement: [false, nil])
      .where(order_service_proposal_status_id: approved_statuses)
      .order(updated_at: :desc)
      .first
    if result.present?
      OrderServiceProposal.ensure_total_values(result)
      return @_approved_proposal = result
    end

    result = order_service_proposals
      .where(order_service_proposal_status_id: approved_statuses)
      .order(updated_at: :desc)
      .first
    OrderServiceProposal.ensure_total_values(result) if result.present?
    @_approved_proposal = result
  end

  def total_value_by_category(category_id)
    main_approved = getting_order_service_proposal_approved
    return 0 unless main_approved

    # Usa items_for_totals que já faz deduplicação correta dos itens
    # de complemento (evita contar 2x itens já copiados para a proposta pai)
    items = OrderServiceProposal.items_for_totals(main_approved)

    items.sum do |item|
      service = item.service
      next 0 unless service
      next 0 unless service.category_id == category_id
      item.total_value.to_f
    end
  end

  def total_parts_value
    total_value_by_category(Category::SERVICOS_PECAS_ID)
  end

  def total_services_value
    total_value_by_category(Category::SERVICOS_SERVICOS_ID)
  end

  # Método auxiliar para retornar o valor total da OS (peças + serviços)
  def total_value
    total_parts_value + total_services_value
  end

  def self.generate_dashboard_to_charts(order_services, cost_centers, cost_center_ids = nil, sub_unit_ids = nil)
    required_order_service_statuses = OrderServiceStatus::REQUIRED_ORDER_SERVICE_STATUSES
    required_proposal_statuses = OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES

    charts = {}
    components = {}

    selected_cost_center_ids = cost_center_ids.presence || cost_centers.map(&:id)

    if selected_cost_center_ids.blank? && sub_unit_ids.blank?
      return { charts: {}, components: {}, all: 0 }
    end

    # Query otimizada: agrupa direto no SQL para evitar N+1
    # Soma total_value das propostas por centro de custo e status da OS
    # Usa SQL explícito para evitar conflito com default_scope do OrderService
    results = OrderServiceProposal
      .joins("INNER JOIN order_services ON order_services.id = order_service_proposals.order_service_id")
      .joins("INNER JOIN vehicles ON vehicles.id = order_services.vehicle_id")
      .joins("INNER JOIN cost_centers ON cost_centers.id = vehicles.cost_center_id")
      .where(order_services: { order_service_status_id: required_order_service_statuses })
      .where(order_service_proposal_status_id: required_proposal_statuses)
      .where(is_complement: [false, nil])
      .where(
        "vehicles.cost_center_id IN (?) OR vehicles.sub_unit_id IN (?)",
        Array(selected_cost_center_ids), Array(sub_unit_ids)
      )
      .group("cost_centers.name", "order_services.order_service_status_id")
      .sum(:total_value)

    approved_by_cost_center = Hash.new(0.0)
    authorized_by_cost_center = Hash.new(0.0)

    results.each do |(cc_name, os_status_id), total|
      if os_status_id == OrderServiceStatus::APROVADA_ID
        approved_by_cost_center[cc_name] += total.to_f
      else
        authorized_by_cost_center[cc_name] += total.to_f
      end
    end

    cost_centers.each do |cost_center|
      approved_total = approved_by_cost_center[cost_center.name]
      authorized_total = authorized_by_cost_center[cost_center.name]
      next unless approved_total.positive? || authorized_total.positive?

      charts[cost_center.name] = approved_total
      components[cost_center.name] = authorized_total
    end

    max_chart_value = charts.values.max || 0
    max_component_value = components.values.max || 0
    max_value = [max_chart_value, max_component_value].max

    {
      charts: charts,
      components: components,
      all: max_value
    }
  end

  def self.getting_vehicles_to_charts(order_services, cost_centers, cost_center_ids = nil, sub_unit_ids = nil)
    # Filtrar veículos pelos cost_centers e sub_units permitidos
    vehicles_query = Vehicle.where(cost_center_id: cost_center_ids || cost_centers.map(&:id))
    vehicles_query = vehicles_query.or(Vehicle.where(sub_unit_id: sub_unit_ids)) if sub_unit_ids.present?
    
    active_vehicles = vehicles_query.where(active: true).count
    inactive_vehicles = vehicles_query.where(active: false).count
    
    return {
      'Ativos' => active_vehicles,
      'Inativos' => inactive_vehicles
    }
  end

  def self.getting_cost_center_values(order_services, cost_centers, cost_center_ids = nil, sub_unit_ids = nil)
    required_order_service_statuses = OrderServiceStatus::REQUIRED_ORDER_SERVICE_STATUSES
    required_proposal_statuses = OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES

    selected_cost_center_ids = cost_center_ids.presence || cost_centers.map(&:id)

    # 1) Saldo inicial = soma dos valores totais dos contratos ATIVOS
    # Contract usa HABTM com cost_centers (tabela contracts_cost_centers)
    contract_ids_from_cost_centers = Contract
      .joins("INNER JOIN contracts_cost_centers ON contracts_cost_centers.contract_id = contracts.id")
      .where("contracts_cost_centers.cost_center_id IN (?)", Array(selected_cost_center_ids))
      .where(active: true)
      .pluck(:id)

    commitment_contract_ids = Commitment.by_cost_center_or_sub_unit_ids(selected_cost_center_ids, sub_unit_ids)
      .where(active: true)
      .where.not(contract_id: nil)
      .pluck(:contract_id)

    all_contract_ids = (contract_ids_from_cost_centers + commitment_contract_ids).uniq
    total_contracts_value = Contract.where(id: all_contract_ids, active: true).sum(:total_value).to_f

    # 2) Saldo dos empenhos ATIVOS (com cancelamentos em uma única query)
    commitments_with_cancels = Commitment
      .by_cost_center_or_sub_unit_ids(selected_cost_center_ids, sub_unit_ids)
      .where(active: true)
      .left_joins(:cancel_commitments)
      .group("commitments.id")
      .pluck(Arel.sql("commitments.commitment_value, COALESCE(SUM(cancel_commitments.value), 0)"))

    total_commitments_value = commitments_with_cancels.sum { |cv, cancel| cv.to_f - cancel.to_f }

    # 3) Saldo consumido = soma via SQL (evita N+1)
    # Usa SQL explícito para evitar conflito com default_scope do OrderService
    total_consumed = OrderServiceProposal
      .joins("INNER JOIN order_services ON order_services.id = order_service_proposals.order_service_id")
      .joins("INNER JOIN vehicles ON vehicles.id = order_services.vehicle_id")
      .where(order_services: { order_service_status_id: required_order_service_statuses })
      .where(order_service_proposal_status_id: required_proposal_statuses)
      .where(is_complement: [false, nil])
      .where(
        "vehicles.cost_center_id IN (?) OR vehicles.sub_unit_id IN (?)",
        Array(selected_cost_center_ids), Array(sub_unit_ids)
      )
      .sum(:total_value).to_f

    # 4) Saldo restante do contrato
    remaining_contract_value = [total_contracts_value - total_consumed, 0].max
    
    # 5) Saldo disponível para empenho
    available_for_commitment = [total_contracts_value - total_commitments_value, 0].max

    {
      'Saldo inicial' => total_contracts_value.round(2),
      'Saldo consumido' => total_consumed.round(2),
      'Saldo restante' => remaining_contract_value.round(2),
      'Saldo disponível para empenho' => available_for_commitment.round(2)
    }
  end

  def self.getting_values_by_type(order_services, cost_centers, cost_center_ids = nil, sub_unit_ids = nil)
    required_order_service_statuses = OrderServiceStatus::REQUIRED_ORDER_SERVICE_STATUSES
    required_proposal_statuses = OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES

    selected_cost_center_ids = cost_center_ids.presence || cost_centers.map(&:id)

    if selected_cost_center_ids.blank? && sub_unit_ids.blank?
      return { 'Peças' => 0.0, 'Serviços' => 0.0 }
    end

    # Soma por categoria incluindo itens sem service_id (inner join com services os omitia)
    items_scope = OrderServiceProposalItem.unscoped
      .joins("INNER JOIN order_service_proposals ON order_service_proposals.id = order_service_proposal_items.order_service_proposal_id")
      .joins("INNER JOIN order_services ON order_services.id = order_service_proposals.order_service_id")
      .joins("INNER JOIN vehicles ON vehicles.id = order_services.vehicle_id")
      .where(order_services: { order_service_status_id: required_order_service_statuses })
      .where(order_service_proposals: { order_service_proposal_status_id: required_proposal_statuses })
      .where(
        "vehicles.cost_center_id IN (?) OR vehicles.sub_unit_id IN (?)",
        Array(selected_cost_center_ids), Array(sub_unit_ids)
      )

    {
      'Peças' => OrderServiceProposalItem.sum_parts_total_value(items_scope).to_f.round(2),
      'Serviços' => OrderServiceProposalItem.sum_services_total_value(items_scope).to_f.round(2)
    }
  end

  def get_cost_center_id
    self.vehicle&.cost_center_id || nil
  end

  def get_sub_unit_id
    self.vehicle&.sub_unit_id || nil
  end

  def getting_text_to_order_service_proposal_status(user)
    result = ""
    register = self.order_service_proposals.select{|item| item.provider_id == user.id && [
        OrderServiceProposalStatus::EM_CADASTRO_ID
      ].include?(item.order_service_proposal_status_id)}.length > 0
    return register
  end

  def self.getting_invoice_data(order_service)
    order_service_proposal_approved = order_service.getting_order_service_proposal_approved
    order_service_invoices = []
    if order_service_proposal_approved
      order_service_invoices = order_service_proposal_approved.order_service_invoices.sort_by{|item| item.order_service_invoice_type_id.to_i}
      order_service_invoices_grouped = order_service_proposal_approved.order_service_invoices.group_by(&:order_service_invoice_type_id)
    end
    return [order_service_invoices, order_service_invoices_grouped, order_service_proposal_approved]
  end

  def self.reprove_all_by_edition(order_service, current_user)
    order_service.order_service_proposals.each do |order_service_proposal|
      OrderServiceProposal.generate_historic(order_service_proposal, current_user, order_service_proposal.order_service_proposal_status_id, OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID)
      order_service_proposal.update_columns(
        order_service_proposal_status_id: OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
        reproved: true,
        reason_reproved: "Ordem de serviço alterada."
      )
    end
  end

  def warranty_items_for_vehicle
    return [] if vehicle_id.blank?

    today = Time.zone.today
    valid_statuses = OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES

    OrderServiceProposalItem
      .joins(order_service_proposal: :order_service)
      .includes(:service, order_service_proposal: [:provider, :order_service])
      .where(order_services: { vehicle_id: vehicle_id })
      .where(order_service_proposals: { order_service_proposal_status_id: valid_statuses })
      .where.not(order_service_proposal_items: { warranty_period: [nil, 0] })
      .map do |item|
        # A garantia começa a contar a partir da data de autorização
        # Se warranty_start_date não estiver preenchido, usa created_at (comportamento legado)
        start_date = item.warranty_start_date || item.created_at.to_date
        expires_at = start_date + item.warranty_period.days
        remaining_days = (expires_at - today).to_i
        next if remaining_days < 0

        service = item.service
        unity_value = item.unity_value || 0
        quantity = item.quantity || 1
        total_value = item.total_value || (unity_value.to_f * quantity.to_f)

        {
          name: item.service_name.presence || service&.name,
          brand: item.brand.presence || service&.brand,
          code: service&.code,
          value: total_value,
          remaining_days: remaining_days,
          expires_at: expires_at,
          provider_name: item.order_service_proposal.provider&.name,
          order_service_code: item.order_service_proposal.order_service&.code,
          order_service_id: item.order_service_proposal.order_service_id
        }
      end
      .compact
      .sort_by { |row| row[:expires_at] }
  end

  def check_commitment_balance(parts_value, services_value, proposal: nil)
    # Retorna hash com status e mensagem de erro
    result = { valid: true, message: nil }

    if proposal.present?
      items = OrderServiceProposal.items_for_totals(proposal)
      parts_value = items.sum { |i| i.category_id_for_commitment == Category::SERVICOS_PECAS_ID ? i.total_value.to_d : 0.to_d }
      services_value = items.sum { |i| i.category_id_for_commitment == Category::SERVICOS_SERVICOS_ID ? i.total_value.to_d : 0.to_d }
    else
      parts_value = (parts_value || 0).to_d
      services_value = (services_value || 0).to_d
    end

    # Se usa empenho global
    if commitment_id.present?
      unless commitment.present?
        result[:valid] = false
        result[:message] = "Empenho Global não encontrado"
        return result
      end

      total_value = parts_value + services_value
      available = commitment.get_available_balance
      
      if total_value > available
        result[:valid] = false
        result[:message] = "Saldo insuficiente no Empenho Global. Disponível: #{ActionController::Base.helpers.number_to_currency(available, unit: 'R$ ', separator: ',', delimiter: '.')}, Necessário: #{ActionController::Base.helpers.number_to_currency(total_value, unit: 'R$ ', separator: ',', delimiter: '.')}"
      end
      return result
    end

    errors = []

    # Verifica empenho de peças
    if parts_value.to_f.positive?
      if commitment_parts_id.blank?
        errors << "Empenho de Peças não selecionado para OS com itens de peças"
      elsif !commitment_parts.present?
        errors << "Empenho de Peças não encontrado"
      else
        available_parts = commitment_parts.get_available_balance
        if parts_value > available_parts
          errors << "Saldo insuficiente no Empenho de Peças. Disponível: #{ActionController::Base.helpers.number_to_currency(available_parts, unit: 'R$ ', separator: ',', delimiter: '.')}, Necessário: #{ActionController::Base.helpers.number_to_currency(parts_value, unit: 'R$ ', separator: ',', delimiter: '.')}"
        end
      end
    end

    # Verifica empenho de serviços
    if services_value.to_f.positive?
      if commitment_services_id.blank?
        errors << "Empenho de Serviços não selecionado para OS com itens de serviços"
      elsif !commitment_services.present?
        errors << "Empenho de Serviços não encontrado"
      else
        available_services = commitment_services.get_available_balance
        if services_value > available_services
          errors << "Saldo insuficiente no Empenho de Serviços. Disponível: #{ActionController::Base.helpers.number_to_currency(available_services, unit: 'R$ ', separator: ',', delimiter: '.')}, Necessário: #{ActionController::Base.helpers.number_to_currency(services_value, unit: 'R$ ', separator: ',', delimiter: '.')}"
        end
      end
    end

    if errors.any?
      result[:valid] = false
      result[:message] = errors.join(' | ')
    end

    result
  end

  # Versão com lock pessimista (FOR UPDATE) para prevenir race conditions
  # em aprovações simultâneas que consomem o mesmo saldo de empenho
  def check_commitment_balance_with_lock!(parts_value, services_value, proposal: nil)
    # Adquire lock FOR UPDATE nos empenhos relacionados
    if commitment_id.present? && commitment.present?
      Commitment.lock("FOR UPDATE").find(commitment_id)
    end
    if commitment_parts_id.present? && commitment_parts.present?
      Commitment.lock("FOR UPDATE").find(commitment_parts_id)
    end
    if commitment_services_id.present? && commitment_services.present?
      Commitment.lock("FOR UPDATE").find(commitment_services_id)
    end

    # Re-verifica saldo após adquirir os locks
    check_commitment_balance(parts_value, services_value, proposal: proposal)
  end

  # Mapeamento entre status da OS e status da Proposta
  OS_TO_PROPOSAL_STATUS = {
    OrderServiceStatus::APROVADA_ID => OrderServiceProposalStatus::APROVADA_ID,
    OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID => OrderServiceProposalStatus::NOTAS_INSERIDAS_ID,
    OrderServiceStatus::AUTORIZADA_ID => OrderServiceProposalStatus::AUTORIZADA_ID,
    OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID => OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
    OrderServiceStatus::PAGA_ID => OrderServiceProposalStatus::PAGA_ID
  }.freeze

  # Sincroniza o status das propostas ativas com o status da OS
  # Previne dessincronização entre o que o admin vê (OS) e o fornecedor vê (proposta)
  def sync_proposals_status!
    target_proposal_status = OS_TO_PROPOSAL_STATUS[order_service_status_id]
    return unless target_proposal_status.present?

    # Só avança propostas que estão "atrás" do status da OS (nunca regride)
    # Ignora canceladas (9), reprovadas (8) e complementos
    eligible_statuses = OS_TO_PROPOSAL_STATUS.values.select { |s| s < target_proposal_status }
    unless eligible_statuses.empty?
      proposals_to_sync = order_service_proposals
        .where(is_complement: [false, nil])
        .where(order_service_proposal_status_id: eligible_statuses)
        .where.not(order_service_proposal_status_id: [
          OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
          OrderServiceProposalStatus::CANCELADA_ID
        ])

      proposals_to_sync.each do |proposal|
        # Não promover proposta de fornecedor divergente da OS (evita duas "Autorizada" em cotação)
        if provider_id.present? && proposal.provider_id != provider_id
          Rails.logger.info "[SYNC_STATUS] Proposta #{proposal.id} ignorada (provider #{proposal.provider_id} != OS #{provider_id})"
          next
        end

        Rails.logger.info "[SYNC_STATUS] Proposta #{proposal.id}: #{proposal.order_service_proposal_status_id} -> #{target_proposal_status} (OS #{id} status #{order_service_status_id})"
        proposal.update_columns(order_service_proposal_status_id: target_proposal_status)
      end
    end

    resolve_duplicate_authorized_proposals! if should_resolve_duplicate_proposals?
  end

  # Garante no máximo uma proposta principal em status "ativa" (Autorizada ou posterior) por OS.
  def resolve_duplicate_authorized_proposals!
    high = [
      OrderServiceProposalStatus::AUTORIZADA_ID,
      OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
      OrderServiceProposalStatus::PAGA_ID
    ]
    scope = order_service_proposals
      .where(is_complement: [false, nil])
      .where(order_service_proposal_status_id: high)
    return if scope.count <= 1

    keeper =
      if provider_id.present? && scope.where(provider_id: provider_id).exists?
        scope.where(provider_id: provider_id).order(updated_at: :desc).first
      else
        scope.order(updated_at: :desc).first
      end
    return unless keeper

    scope.where.not(id: keeper.id).find_each do |prop|
      prop.update_columns(
        order_service_proposal_status_id: OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
        reproved: true,
        reason_reproved: 'Proposta concorrente: a OS permanece vinculada a outro fornecedor.'
      )
    end
  end

  def should_resolve_duplicate_proposals?
    return false unless provider_id.present?

    high = [
      OrderServiceProposalStatus::AUTORIZADA_ID,
      OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
      OrderServiceProposalStatus::PAGA_ID
    ]
    order_service_proposals.where(is_complement: [false, nil], order_service_proposal_status_id: high).count > 1
  end

  private

  def generate_code
    result = ""
    id = self.id.to_s
    today = self.created_at.to_date
    year = today.strftime('%y')   # 2 dígitos do ano (ex: 26)
    month = today.strftime('%m')  # mês com zero (ex: 03)
    result = "OS#{id}-#{year}#{month}"
    self.update_columns(code: result)
  end

  def default_values
    self.code ||= ""
    self.driver ||= ""
    self.details ||= ""
    self.cancel_justification ||= ""
    self.order_service_type_id ||= OrderServiceType::COTACOES_ID
    self.order_service_status_id ||= OrderServiceStatus::EM_ABERTO_ID
    self.invoice_part_ir ||= 1.2
    self.invoice_part_pis ||= 0.65
    self.invoice_part_cofins ||= 3
    self.invoice_part_csll ||= 1
    self.invoice_service_ir ||= 4.8
    self.invoice_service_pis ||= 0.65
    self.invoice_service_cofins ||= 3
    self.invoice_service_csll ||= 1
  end

  def validate_min_km
    last_km = self.vehicle.getting_last_km
    # Não permite km igual ou menor que o último - precisa ser maior
    if !self.km.nil? && last_km > 0 && self.km <= last_km
      errors.add(:km, "deve ser maior que o último km registrado (#{last_km})")
    end
  end

  def validate_vehicle_photos
    # Valida se há pelo menos uma foto anexada quando o cliente exige fotos
    if vehicle_photos.attached? == false || vehicle_photos.count == 0
      errors.add(:vehicle_photos, "é obrigatório anexar pelo menos uma foto do veículo")
    end
  end

  def validate_commitment_presence
    # Valida que pelo menos UM empenho foi selecionado na criação da OS
    if commitment_id.blank? && commitment_parts_id.blank? && commitment_services_id.blank?
      errors.add(:base, "Pelo menos um empenho (Geral, Peças ou Serviços) deve ser selecionado")
    end
  end

  def validate_commitments_by_category
    # Se a OS tem itens de peças, deve ter empenho de peças
    if has_parts? && commitment_parts_id.blank? && commitment_id.blank?
      errors.add(:commitment_parts_id, "deve ser selecionado quando há itens de peças")
    end
    
    # Se a OS tem itens de serviços, deve ter empenho de serviços
    if has_services? && commitment_services_id.blank? && commitment_id.blank?
      errors.add(:commitment_services_id, "deve ser selecionado quando há itens de serviços")
    end
  end
  
  def has_parts?
    part_service_order_services.includes(:service).any? do |item|
      item.category_id_for_commitment == Category::SERVICOS_PECAS_ID
    end
  end

  def has_services?
    part_service_order_services.includes(:service).any? do |item|
      item.category_id_for_commitment == Category::SERVICOS_SERVICOS_ID
    end
  end

  def validate_provider_for_diagnostico
    if order_service_type_id == OrderServiceType::DIAGNOSTICO_ID && provider_id.blank?
      errors.add(:provider_id, "deve ser selecionado para ordens de serviço do tipo Diagnóstico")
    end
  end

  def validate_service_group_for_requisicao
    # Se o tipo for Requisição, service_group_id é obrigatório
    if order_service_type_id == OrderServiceType::REQUISICAO_ID && service_group_id.blank?
      errors.add(:service_group_id, "deve ser selecionado para ordens de serviço do tipo Requisição")
    end
  end

  def validate_services_in_service_group
    # Se o tipo for Requisição e tiver grupo de serviço, validar peças/serviços
    return unless order_service_type_id == OrderServiceType::REQUISICAO_ID && service_group_id.present?
    return unless service_group.present?

    # Buscar IDs de serviços permitidos no grupo
    allowed_service_ids = service_group.service_group_items.pluck(:service_id)
    
    # Se o grupo não tem itens cadastrados, bloquear
    if allowed_service_ids.empty?
      errors.add(:base, "O grupo de serviço #{service_group.name} não possui peças/serviços cadastrados. Configure o grupo antes de criar a OS.")
      return
    end

    # Validar cada item da OS
    part_service_order_services.each do |item|
      next if item.service_id.blank?
      
      unless allowed_service_ids.include?(item.service_id)
        errors.add(:base, "A peça/serviço '#{item.service.name}' não está cadastrada no grupo #{service_group.name}")
      end

      # Buscar o item do grupo para validar quantidade e valor
      group_item = service_group.service_group_items.find_by(service_id: item.service_id)
      next unless group_item

      # Validar quantidade (com tolerância zero - não permite exceder)
      item_quantity = item.quantity || 0
      max_quantity = group_item.quantity || 0
      
      if item_quantity > max_quantity
        errors.add(:base, "❌ A quantidade de '#{item.service.name}' (#{item_quantity}) excede o limite permitido pelo grupo (máximo: #{group_item.formatted_quantity}). Ajuste a quantidade para continuar.")
      end

      # Validar valor total do item (preço está no Service, não no PartServiceOrderService)
      service_price = item.service&.price || 0
      item_total = (item.quantity || 0) * service_price
      if group_item.max_value.present? && group_item.max_value > 0 && item_total > group_item.max_value
        errors.add(:base, "Valor total de '#{item.service.name}' (#{ActionController::Base.helpers.number_to_currency(item_total, unit: 'R$ ', separator: ',', delimiter: '.')}) excede o limite do grupo (#{group_item.formatted_max_value})")
      end
    end
  end

end
