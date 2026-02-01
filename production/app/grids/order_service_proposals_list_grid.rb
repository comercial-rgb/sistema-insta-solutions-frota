class OrderServiceProposalsListGrid

  include Datagrid

  Datagrid.configure do |config|
    config.date_formats = ["%d/%m/%Y", "%d-%m-%Y"]
    config.datetime_formats = ["%d/%m/%Y %H:%M", "%d-%m-%Y %H:%M"]
  end

  scope do
    OrderServiceProposal.all
  end

  attr_accessor :current_user, :providers, :order_service
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

  def check_not_provider
    return !current_user.provider?
  end

  def get_providers
    return providers
  end

  def check_select_all
    return [OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID].include?(order_service.order_service_status_id)
  end

  filter(:provider_id, :enum, if: :check_not_provider, select: :get_providers, header: OrderServiceProposal.human_attribute_name(:provider_id), include_blank: I18n.t('model.select_option') ) do |value, relation, grid|
    relation.by_provider_id(value)
  end

  filter(:code, :string, if: :check_user, header: OrderServiceProposal.human_attribute_name(:code)) do |value, relation, grid|
    relation.by_code(value)
  end

  filter(:created_at, :date, :range => true, if: :check_user, :header => OrderServiceProposal.human_attribute_name(:created_at)) do |value, relation, grid|
    relation.by_initial_date(value[0]).by_final_date(value[1])
  end

  filter(:total_discount, :integer, :range => true, if: :check_user, :header => OrderServiceProposal.human_attribute_name(:total_discount)) do |value, relation, grid|
    relation.by_initial_total_discount(value[0]).by_final_total_discount(value[1])
  end

  filter(:total_value, :integer, :range => true, if: :check_user, :header => OrderServiceProposal.human_attribute_name(:total_value)) do |value, relation, grid|
    relation.by_initial_total_value(value[0]).by_final_total_value(value[1])
  end

  column(:select_register, if: :check_select_all, html: true, header: "#" ) do |record, grid|
    if record.order_service_proposal_status_id == OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID
      render "common_pages/datagrid/select_register", record: record, current_model: "order-service-proposal"
    end
  end

  column(:provider_id, order: 'providers.get_name', if: :check_not_provider, header: OrderServiceProposal.human_attribute_name(:provider_id) ) do |record, grid|
    if record.provider
      record.provider.get_name
    end
  end

  column(:code, order: :code, html: false, if: :check_user, header: OrderServiceProposal.human_attribute_name(:code) ) do |record, grid|
    record.code
  end

  column(:code, order: :code, html: true, if: :check_user, header: OrderServiceProposal.human_attribute_name(:code) ) do |record, grid|
    link_to record.code, show_order_service_proposal_path(id: record.id), target: '_blank'
  end

  column(:total_value_without_discount, if: :check_user, order: 'order_service_proposals.total_value_without_discount', header: OrderServiceProposal.human_attribute_name(:total_value_without_discount) ) do |record, grid|
    CustomHelper.to_currency(record.total_value_without_discount)
  end

  column(:total_discount, if: :check_user, order: 'order_service_proposals.total_discount', header: OrderServiceProposal.human_attribute_name(:total_discount) ) do |record, grid|
    CustomHelper.to_currency(record.total_discount)
  end

  column(:total_value, if: :check_user, order: 'order_service_proposals.total_value', header: OrderServiceProposal.human_attribute_name(:total_value) ) do |record, grid|
    CustomHelper.to_currency(record.total_value)
  end

  column(:order_service_status_proposal_id, html: false, if: :check_user, order: :order_service_status_proposal_id, header: OrderServiceProposal.human_attribute_name(:order_service_proposal_status_id) ) do |record, grid|
    if record.order_service_status_proposal
      record.order_service_status_proposal.name
    end
  end

  column(:order_service_status_proposal_id, html: true, if: :check_user, header: OrderServiceProposal.human_attribute_name(:order_service_proposal_status_id) ) do |record, grid|
    render "order_service_proposals/order_service_proposal_status", record: record
  end

  column(:created_at, if: :check_user, order: 'created_at', header: OrderServiceProposal.human_attribute_name(:created_at) ) do |record, grid|
    CustomHelper.get_text_date(record.created_at, 'datetime', :full)
  end

  column(:actions, if: :check_not_provider, html: true, header: OrderServiceProposal.human_attribute_name(:actions) ) do |record, grid|
    render "proposal_actions", record: record
  end

end
