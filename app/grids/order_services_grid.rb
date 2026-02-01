class OrderServicesGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    OrderService.all
  end

  attr_accessor :current_user,
  :clients, :managers, :cost_centers,
  :vehicles, :provider_service_types,
  :order_service_types, :current_order_service_status_id,
  :providers, :show_order_service_status,
  :period_filter, :method, :commitments, :sub_units

  # grid.current_user para acessar o usuário
  # grid[:id] para acessar o filtro atual (no id, por exemplo)
  # grid[:created_at][0] para acessar o filtro atual quando for range true

  def check_user
    # return (!current_user.user?)
    return true
  end

  def check_admin
    return current_user.admin?
  end

  def check_admin_or_provider
    return (current_user.admin? || current_user.provider?)
  end

  def check_not_provider
    return !current_user.provider?
  end

  def check_provider
    return current_user.provider?
  end

  def check_show_order_service_status
    return (!show_order_service_status.nil? && show_order_service_status) && show_order_service_status && (current_user.admin? || current_user.manager?)
  end

  def check_show_actions
    return (show_order_service_status.nil? || !show_order_service_status) && !check_current_rejected_order_service_status && !show_order_service_proposal_status
  end

  def check_current_rejected_order_service_status
    return ((current_user.admin? || current_user.manager?) && !current_order_service_status_id.nil? && current_order_service_status_id == OrderServiceStatus::TEMP_REJEITADA_ID)
  end

  # def show_order_service_status
  #   return (!current_user.provider?)
  # end

  def show_order_service_proposal_status
    return (method == 'index' && current_user.provider?)
  end

  def get_vehicles
    return vehicles
  end

  def get_clients
    return clients
  end

  def get_managers
    return managers
  end

  def get_cost_centers
    return cost_centers
  end

  def get_commitments
    return commitments
  end

  def get_sub_units
    return sub_units
  end

  def get_provider_service_types
    return provider_service_types
  end

  def get_order_service_types
    return order_service_types
  end

  def get_providers
    return providers
  end

  def check_select_all
    if [OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID, OrderServiceStatus::AUTORIZADA_ID, OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID].include?(current_order_service_status_id)
      return (current_user.admin? || (!current_user.admin? && current_order_service_status_id == OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID))
    else
      return false
    end
  end

  def show_period_filter
    return !period_filter.nil? && period_filter
  end

  filter(:month, :enum, if: :show_period_filter, select: CustomHelper.get_months_options, header: OrderService.human_attribute_name(:month), include_blank: false, default: Date.today.month ) do |value, relation, grid|
  end

  filter(:year, :enum, if: :show_period_filter, select: CustomHelper.get_years(2024, Date.today.year), header: OrderService.human_attribute_name(:year), include_blank: false, default: Date.today.year ) do |value, relation, grid|
  end

  filter(:client_id, :enum, if: :check_admin_or_provider, select: :get_clients, header: OrderService.human_attribute_name(:client_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_client_id(value)
  end

  filter(:manager_id, :enum, if: :check_admin, select: :get_managers, header: OrderService.human_attribute_name(:manager_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_manager_id(value)
  end

  filter(:provider_id, :enum, if: :check_admin, select: :get_providers, header: OrderService.human_attribute_name(:provider_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_proposal_provider_id(value)
  end

  filter(:cost_center_id, :enum, if: :check_not_provider, select: :get_cost_centers, header: OrderService.human_attribute_name(:cost_center_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_cost_center_id(value)
  end

  filter(:commitment_id, :enum, if: :check_not_provider, select: :get_commitments, header: OrderService.human_attribute_name(:commitment_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_commitment_id(value)
  end

  filter(:sub_unit_id, :enum, if: :check_not_provider, select: :get_sub_units, header: OrderService.human_attribute_name(:sub_unit_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_sub_unit_id(value)
  end

  filter(:vehicle_id, :enum, if: :check_not_provider, select: :get_vehicles, header: OrderService.human_attribute_name(:vehicle_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_vehicle_id(value)
  end

  filter(:provider_service_type_id, :enum, if: :check_user, select: :get_provider_service_types, header: OrderService.human_attribute_name(:provider_service_type_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_provider_service_type_id(value)
  end

  filter(:order_service_type_id, :enum, if: :check_user, select: :get_order_service_types, header: OrderService.human_attribute_name(:order_service_type_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_order_service_type_id(value)
  end

  filter(:data_inserted_by_provider, :enum, if: :check_user, select: CustomHelper.return_select_options_yes_no, header: OrderService.human_attribute_name(:data_inserted_by_provider), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_data_inserted_by_provider(value)
  end

  filter(:release_quotation, :enum, if: :check_user, select: CustomHelper.return_select_options_yes_no, header: OrderService.human_attribute_name(:release_quotation), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_release_quotation(value)
  end

  filter(:order_service_status_id, :enum, if: :check_show_order_service_status, select: proc { OrderServiceStatus.menu_ordered.map {|c| [c.name, c.id] }}, header: OrderService.human_attribute_name(:order_service_status_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_order_service_status_id(value)
  end

  filter(:order_service_proposal_status_id, :enum, if: :show_order_service_proposal_status, select: proc { OrderServiceProposalStatus.where.not(id: [OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID]).order(:id).map {|c| [c.name, c.id] }}, header: OrderServiceProposal.human_attribute_name(:order_service_proposal_status_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_order_service_proposal_status_id(value)
  end

  filter(:code, :string, if: :check_user, header: OrderService.human_attribute_name(:code)) do |value, relation, grid|
    relation.by_code(value)
  end

  filter(:created_at, :date, :range => true, if: :check_user, :header => OrderService.human_attribute_name(:created_at)) do |value, relation, grid|
    relation.by_initial_date(value[0]).by_final_date(value[1])
  end

  filter(:updated_at, :date, :range => true, if: :check_not_provider, :header => OrderService.human_attribute_name(:updated_at)) do |value, relation, grid|
    relation.by_initial_updated_at(value[0]).by_final_updated_at(value[1])
  end

  column(:select_register, if: :check_select_all, html: true, header: "#" ) do |record, grid|
    render "common_pages/datagrid/select_register", record: record, current_model: "order-service"
  end

  column(:client_id, if: :check_admin, order: :client_id, header: OrderService.human_attribute_name(:client_id) ) do |record, grid|
    if record.client
      record.client.fantasy_name
    end
  end

  column(:client_id, if: :check_provider, html: false, order: :client_id, header: OrderService.human_attribute_name(:client_id) ) do |record, grid|
    if record.client
      (record.client.fantasy_name+" - "+record.cost_center.get_text_name+(record.sub_unit.nil? ? "" : " - "+record.sub_unit.get_text_name))
    end
  end

  column(:client_id, if: :check_provider, html: true, order: :client_id, header: OrderService.human_attribute_name(:client_id) ) do |record, grid|
    if record.client
      (record.client.fantasy_name + "<br/><small>"+record.cost_center.get_text_name+"</small>"+(record.sub_unit.nil? ? "" : "<br/><small>"+record.sub_unit.get_text_name+"</small>")).html_safe
    end
  end

  column(:code, order: :code, html: false, if: :check_user, header: OrderService.human_attribute_name(:code) ) do |record, grid|
    pending_badge = ""
    # Verifica se há propostas aguardando aprovação inicial do gestor
    if (grid.current_user.manager? || grid.current_user.admin?) && record.approved_proposal.blank? && record.order_service_proposals.any? { |p| p.pending_manager_approval || p.pending_manager_authorization }
      pending_badge = " [Aguardando Gestor]"
    end
    # Verifica se há COMPLEMENTOS aguardando aprovação do gestor
    if (grid.current_user.manager? || grid.current_user.admin?) && record.approved_proposal.present?
      pending_complements = record.order_service_proposals.where(
        is_complement: true,
        order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
      )
      if pending_complements.any?
        pending_badge = " [Aguardando Complemento]"
      end
    end
    record.code + pending_badge
  end

  column(:code, order: :code, html: true, if: :check_user, header: OrderService.human_attribute_name(:code) ) do |record, grid|
    pending_badge = ""
    # Verifica se há propostas aguardando aprovação inicial do gestor
    if (grid.current_user.manager? || grid.current_user.admin?) && record.approved_proposal.blank? && record.order_service_proposals.any? { |p| p.pending_manager_approval || p.pending_manager_authorization }
      pending_badge = '<br><span class="badge" style="background-color: #ffc107; color: #000; font-size: 0.75rem; padding: 0.25rem 0.5rem; margin-top: 0.25rem;">Aguardando Gestor</span>'.html_safe
    end
    # Verifica se há COMPLEMENTOS aguardando aprovação do gestor
    if (grid.current_user.manager? || grid.current_user.admin?) && record.approved_proposal.present?
      pending_complements = record.order_service_proposals.where(
        is_complement: true,
        order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
      )
      if pending_complements.any?
        pending_badge = '<br><span class="badge bg-danger text-white" style="font-size: 0.75rem; padding: 0.25rem 0.5rem; margin-top: 0.25rem;"><i class="bi bi-plus-square"></i> Aguardando Complemento</span>'.html_safe
      end
    end
    (render("datagrid_actions", record: record).to_s + pending_badge.to_s).html_safe
  end

  column(:order_service_status_id, html: false, if: :check_show_order_service_status, order: :order_service_status_id, header: OrderService.human_attribute_name(:order_service_status_id) ) do |record, grid|
    record.order_service_status&.name || 'Status não definido'
  end

  column(:order_service_status_id, html: true, if: :check_show_order_service_status, order: :order_service_status_id, header: OrderService.human_attribute_name(:order_service_status_id) ) do |record, grid|
    if record.order_service_status
      render 'show_order_service_status', record: record
    end
  end

  column(:order_service_proposal_status_id, html: false, if: :show_order_service_proposal_status, order: :order_service_proposal_status_id, header: OrderServiceProposal.human_attribute_name(:order_service_proposal_status_id) ) do |record, grid|
    if record.rejected_providers.select{|item| item.provider_id == current_user.id}.present?
      OrderServiceProposal.human_atribute_name(:rejected)
    else
      order_service_proposal = record.order_service_proposals.select{|item| item.provider_id == current_user.id}.first
      if order_service_proposal.present?
        order_service_proposal.order_service_proposal_status.name
      end
    end
  end

  column(:order_service_proposal_status_id, html: true, if: :show_order_service_proposal_status, order: :order_service_proposal_status_id, header: OrderServiceProposal.human_attribute_name(:order_service_proposal_status_id) ) do |record, grid|
    render 'show_order_service_proposal_status', record: record, current_user: grid.current_user
  end

  column(:manager_id, if: :check_admin, order: :manager_id, header: OrderService.human_attribute_name(:manager_id) ) do |record, grid|
    if record.manager
      record.manager.name
    end
  end

  column(:provider_id, if: :check_admin, order: :provider_id, header: OrderService.human_attribute_name(:provider_id) ) do |record, grid|
    if record.provider
      record.provider.fantasy_name.presence || record.provider.name
    else
      order_service_proposal_approved = record.getting_order_service_proposal_approved
      if order_service_proposal_approved
        order_service_proposal_approved.provider.fantasy_name.presence || order_service_proposal_approved.provider.name
      end
    end
  end

  column(:provider_service_type_id, if: :check_user, html: false, order: :provider_service_type_id, header: OrderService.human_attribute_name(:provider_service_type_id) ) do |record, grid|
    if record.provider_service_type
      record.provider_service_type.name
    end
  end

  column(:order_service_type_id, if: :check_user, html: false, order: :order_service_type_id, header: OrderService.human_attribute_name(:order_service_type_id) ) do |record, grid|
    if record.order_service_type
      record.order_service_type.name
    end
  end

  column(:order_service_type_id, if: :check_user, html: true, header: OrderService.human_attribute_name(:order_service_type_id) ) do |record, grid|
    render "order_service_type", record: record
  end

  column(:cost_center, if: :check_not_provider, header: Vehicle.human_attribute_name(:cost_center) ) do |record, grid|
    if record.vehicle && record.vehicle.cost_center
      record.vehicle.cost_center.name
    end
  end

  column(:commitment_id, if: :check_not_provider, html: false, header: OrderService.human_attribute_name(:commitment_id) ) do |record, grid|
    if record.commitment
      # Para CSV/Excel, exibir texto completo
      cost_centers = record.commitment.cost_centers.any? ? record.commitment.cost_centers : [record.commitment.cost_center].compact
      if cost_centers.count > 1
        "#{record.commitment.commitment_number} (#{cost_centers.count} Centros de Custo)"
      else
        record.commitment.get_text_name
      end
    end
  end

  column(:commitment_id, if: :check_not_provider, html: true, header: OrderService.human_attribute_name(:commitment_id) ) do |record, grid|
    if record.commitment
      render "show_commitment_data", record: record
    end
  end

  column(:sub_unit_id, if: :check_not_provider, header: OrderService.human_attribute_name(:sub_unit_id) ) do |record, grid|
    if record.vehicle && record.vehicle.sub_unit
      record.vehicle.sub_unit.get_text_name
    end
  end

  column(:vehicle, if: :check_not_provider, html: true, header: OrderService.human_attribute_name(:vehicle) ) do |record, grid|
    render "show_vehicle_data", record: record
  end

  column(:vehicle_id, if: :check_admin_or_provider, html: false, header: OrderService.human_attribute_name(:vehicle_id) ) do |record, grid|
    if record.vehicle
      record.vehicle.getting_vehicle_data
    end
  end

  column(:vehicle_id, if: :check_provider, html: true, header: OrderService.human_attribute_name(:vehicle_id) ) do |record, grid|
    render "show_vehicle_data", record: record
  end

  column(:total_value_without_discount, header: OrderServiceProposal.human_attribute_name(:total_value_without_discount) ) do |record, grid|
    order_service_proposal_approved = record.getting_order_service_proposal_approved
    if order_service_proposal_approved.present?
      # Calcular valor sem desconto incluindo complementos aprovados
      base_value = order_service_proposal_approved.total_value_without_discount.to_f
      complement_value = order_service_proposal_approved.complement_proposals
        .where(order_service_proposal_status_id: OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES)
        .sum(:total_value_without_discount).to_f
      CustomHelper.to_currency(base_value + complement_value)
    end
  end

  column(:total_discount, header: OrderServiceProposal.human_attribute_name(:total_discount) ) do |record, grid|
    order_service_proposal_approved = record.getting_order_service_proposal_approved
    if order_service_proposal_approved.present?
      # Calcular desconto total incluindo complementos aprovados
      base_discount = order_service_proposal_approved.total_discount.to_f
      complement_discount = order_service_proposal_approved.complement_proposals
        .where(order_service_proposal_status_id: OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES)
        .sum(:total_discount).to_f
      CustomHelper.to_currency(base_discount + complement_discount)
    end
  end

  column(:parts_total_value, header: 'Peças') do |record, grid|
    value = record.total_parts_value
    CustomHelper.to_currency(value) if value
  end

  column(:services_total_value, header: 'Serviços') do |record, grid|
    value = record.total_services_value
    CustomHelper.to_currency(value) if value
  end

  column(:total_value, header: OrderServiceProposal.human_attribute_name(:total_value) ) do |record, grid|
    order_service_proposal_approved = record.getting_order_service_proposal_approved
    if order_service_proposal_approved.present?
      # Usar método que inclui complementos aprovados
      CustomHelper.to_currency(order_service_proposal_approved.total_value_with_complements)
    end
  end

  column(:created_at, if: :check_user, order: :created_at, header: OrderService.human_attribute_name(:created_at) ) do |record, grid|
    CustomHelper.get_text_date(record.created_at, 'datetime', :full)
  end

  column(:show_order_rejecteds, html: true, if: :check_current_rejected_order_service_status, order: :order_service_status_id, header: OrderService.human_attribute_name(:rejecteds) ) do |record, grid|
    render "show_order_rejecteds", record: record
  end

  column(:show_order_rejecteds, html: false, if: :check_current_rejected_order_service_status, header: OrderService.human_attribute_name(:rejecteds) ) do |record, grid|
    record.rejected_providers.map(&:get_name).join(", ")
  end

  column(:updated_at, if: :check_not_provider, order: :updated_at, header: OrderService.human_attribute_name(:updated_at) ) do |record, grid|
    record.getting_last_updated_data
  end

  column(:number, if: :check_admin_or_provider, order: :updated_at, header: OrderServiceInvoice.human_attribute_name(:number) ) do |record, grid|
    result = OrderService.getting_invoice_data(record)
    order_service_invoices = result[0]
    if order_service_invoices.length > 0
      order_service_invoices.map do |item|
        type_name = item.order_service_invoice_type&.name.presence || 'Sem tipo'
        number = item.number.to_s
        "(#{type_name}) #{number}".strip
      end.join(", ")
    end
  end

  # column(:actions, if: :check_show_actions, html: true, header: OrderService.human_attribute_name(:actions) ) do |record, grid|
  #   render "datagrid_actions", record: record
  # end

end
