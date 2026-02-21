class CostCenter < ApplicationRecord
  after_initialize :default_values

  attr_accessor :already_consumed_value, :skip_validations

  default_scope {
    joins(:client)
    .order("users.fantasy_name ASC", "cost_centers.name ASC")
  }

  scope :by_id, lambda { |value| where("cost_centers.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_ids, lambda { |value| where("cost_centers.id IN (?)", value) if !value.nil? }
  scope :by_client_id, lambda { |value| where("cost_centers.client_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_budget_type_id, lambda { |value| where("cost_centers.budget_type_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_has_sub_units, lambda { |value| where("cost_centers.has_sub_units = ?", value) if !value.nil? && !value.blank? }
  scope :by_name, lambda { |value| where("LOWER(cost_centers.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  scope :by_contract_number, lambda { |value| where("LOWER(cost_centers.contract_number) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  scope :by_commitment_number, lambda { |value| where("LOWER(cost_centers.commitment_number) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_initial_consumed_balance, lambda { |value| where("cost_centers.initial_consumed_balance >= ?", value) if !value.nil? && !value.blank? }
  scope :by_final_initial_consumed_balance, lambda { |value| where("cost_centers.initial_consumed_balance <= ?", value) if !value.nil? && !value.blank? }

  scope :by_initial_initial_budget_value, lambda { |value| where("cost_centers.initial_budget_value >= ?", value) if !value.nil? && !value.blank? }
  scope :by_final_initial_budget_value, lambda { |value| where("cost_centers.initial_budget_value <= ?", value) if !value.nil? && !value.blank? }

  scope :by_initial_contract_initial_date, lambda { |value| where("cost_centers.contract_initial_date >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_contract_initial_date, lambda { |value| where("cost_centers.contract_initial_date <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("cost_centers.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("cost_centers.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

  belongs_to :client, :class_name => 'User', foreign_key: 'client_id', optional: true
  belongs_to :budget_type, optional: true
  belongs_to :invoice_state, :class_name => 'State', optional: true

  has_and_belongs_to_many :associated_users, class_name: 'User', join_table: 'cost_centers_users'

  has_many :sub_units, dependent: :destroy
  accepts_nested_attributes_for :sub_units, reject_if: ->(attributes){ attributes['name'].blank? }

  has_many :vehicles, dependent: :destroy

  has_many :order_services, through: :vehicles

  has_many :commitments, dependent: :destroy # Relacionamento legado via cost_center_id
  
  # Novo relacionamento N:N com empenhos
  has_many :commitment_cost_centers, dependent: :destroy
  has_many :linked_commitments, through: :commitment_cost_centers, source: :commitment

  has_and_belongs_to_many :contracts, dependent: :destroy

  validates_presence_of :client_id
  validates_presence_of :name, :budget_type_id, if: Proc.new { |a| a.skip_validations.nil? }

  def get_text_name
    self.name.to_s
  end

  def initial_consumed_balance=(new_initial_consumed_balance)
		self[:initial_consumed_balance] = CustomHelper.currency_to_value(new_initial_consumed_balance)
	end

  def budget_value=(new_budget_value)
		self[:budget_value] = CustomHelper.currency_to_value(new_budget_value)
	end

  def self.getting_data_by_user(current_user)
    if current_user.manager? || current_user.additional?
      cost_center_ids = current_user.associated_cost_centers.map(&:id)
    end
    result = []
    if current_user.admin?
      result = CostCenter.order(:name)
    elsif current_user.client?
      result = CostCenter.by_client_id(current_user.id).order(:name)
    elsif current_user.manager?
      result = CostCenter.by_ids(cost_center_ids).order(:name)
    elsif current_user.additional?
      result = CostCenter.by_ids(cost_center_ids).order(:name)
    end
    return result
  end

  def self.get_total_already_consumed_value(cost_center)
    required_order_service_statuses = OrderServiceStatus::REQUIRED_ORDER_SERVICE_STATUSES
    required_proposal_statuses = OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES

    proposals_total = cost_center.order_services.joins(:order_service_proposals)
                                   .where(order_service_status_id: required_order_service_statuses)
                                   .where(order_service_proposals: { order_service_proposal_status_id: required_proposal_statuses })
                                   .sum("order_service_proposals.total_value")

    initial_balance = cost_center.initial_consumed_balance.to_f
    sub_units_balance = cost_center.has_sub_units ? cost_center.sub_units.sum(:initial_consumed_balance).to_f : 0
    total_consumed = proposals_total + initial_balance + sub_units_balance
    total_consumed
  end

  def self.getting_values_to_cost_centers(cost_center)
    total_already_consumed_value = CostCenter.get_total_already_consumed_value(cost_center)
    sum_budget_value = CostCenter.sum_budget_value(cost_center)
    pendent_value = (sum_budget_value - total_already_consumed_value).to_f
    {
      total_already_consumed_value: total_already_consumed_value.to_f,
      sum_budget_value: sum_budget_value.to_f,
      pendent_value: pendent_value.to_f
    }
  end

  def self.getting_values_to_cost_centers_by_contract(cost_center)
    total_already_consumed_value = CostCenter.get_total_already_consumed_value(cost_center)
    sum_budget_value = CostCenter.sum_budget_value_contract(cost_center)
    pendent_value = (sum_budget_value - total_already_consumed_value).to_f
    {
      total_already_consumed_value: total_already_consumed_value.to_f,
      sum_budget_value: sum_budget_value.to_f,
      pendent_value: pendent_value.to_f
    }
  end

  def self.sum_budget_value(cost_center)
    # Combina empenhos diretos (via cost_center_id) e vinculados (via tabela N:N commitment_cost_centers)
    # Remove duplicatas para não contar o mesmo empenho duas vezes
    direct_ids = cost_center.commitments.pluck(:id)
    linked_ids = cost_center.linked_commitments.pluck(:id)
    all_ids = (direct_ids + linked_ids).uniq

    return 0.0 if all_ids.empty?

    # Reutiliza Commitment.sum_budget_value que já calcula corretamente:
    # commitment_value + aditivos (addendum_commitments) - cancelamentos (cancel_commitments)
    Commitment.where(id: all_ids).sum do |commitment|
      Commitment.sum_budget_value(commitment)
    end.to_f
  end

  def self.sum_budget_value_contract(cost_center)
    # Combina empenhos diretos e vinculados (N:N), sem duplicatas
    direct_ids = cost_center.commitments.pluck(:id)
    linked_ids = cost_center.linked_commitments.pluck(:id)
    all_ids = (direct_ids + linked_ids).uniq

    return 0.0 if all_ids.empty?

    all_commitments = Commitment.where(id: all_ids).includes(:contract)
    contracts = all_commitments.map(&:contract).compact.uniq.select(&:active)
    result = contracts.map { |contract| contract.get_total_value }.sum.to_f
    return result
  end

  def self.getting_by_client_id(current_user, client_id)
    if current_user.admin?
      return CostCenter.by_client_id(client_id).order(:name)
    else
      return CostCenter.by_client_id(current_user.client_id).order(:name)
    end
  end

  def self.getting_data_to_show_in_dashboard(cost_centers)
    result = {}
    begin
      y_data = []
      series_1_data = []
      series_2_data = []
      cost_centers.each do |cost_center|
        y_data.push(cost_center.get_text_name)
        values = CostCenter.getting_values_to_cost_centers(cost_center)
        series_1_data.push(values[:sum_budget_value])
        series_2_data.push(values[:total_already_consumed_value])
      end
      result = {
        y_data: y_data,
        series_1_data: series_1_data,
        series_2_data: series_2_data,
      }
    rescue => e
      Rails.logger.error "Error getting data to show in dashboard: #{e.message}"
      result = {}
    end
    return result
  end

  private

  def default_values
    self.name ||= ""
    self.contract_number ||= ""
    self.commitment_number ||= ""
    self.has_sub_units ||= false if self.has_sub_units.nil?
  end

end
