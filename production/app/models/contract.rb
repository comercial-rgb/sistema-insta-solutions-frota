class Contract < ApplicationRecord
  after_initialize :default_values

  default_scope {
    joins(:client)
    .order('users.social_name ASC', {number: :asc})
  }

  scope :by_id, lambda { |value| where("contracts.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_client_id, lambda { |value| where("contracts.client_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_name, lambda { |value| where("LOWER(contracts.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  scope :by_number, lambda { |value| where("contracts.number = ?", value) if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("contracts.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("contracts.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

  #  scope :by_total_value_range, lambda { |min_value, max_value|
  #   subquery = Contract.joins("LEFT JOIN addendum_contracts ON addendum_contracts.contract_id = contracts.id")
  #                      .select("contracts.id, COALESCE(contracts.total_value, 0) + COALESCE(SUM(addendum_contracts.total_value), 0) AS total_combined_value")
  #                      .group("contracts.id")

  #   query = joins("INNER JOIN (#{subquery.to_sql}) AS combined ON combined.id = contracts.id")

  #   if min_value.present? && max_value.present?
  #     query.where("combined.total_combined_value >= ? AND combined.total_combined_value <= ?", min_value, max_value)
  #   elsif min_value.present?
  #     query.where("combined.total_combined_value >= ?", min_value)
  #   elsif max_value.present?
  #     query.where("combined.total_combined_value <= ?", max_value)
  #   else
  #     query
  #   end
  # }

  scope :by_initial_total_value, lambda { |value|
  if value.present?
      subquery = Contract.joins("LEFT JOIN addendum_contracts ON addendum_contracts.contract_id = contracts.id")
        .select("contracts.id")
        .group("contracts.id")
        .having("SUM(contracts.total_value + COALESCE(addendum_contracts.total_value, 0)) >= ?", value.to_f)
        .pluck(:id)

      where(id: subquery)
    end
  }

  scope :by_final_total_value, lambda { |value|
    if value.present?
      subquery = Contract.joins("LEFT JOIN addendum_contracts ON addendum_contracts.contract_id = contracts.id")
        .select("contracts.id")
        .group("contracts.id")
        .having("SUM(contracts.total_value + COALESCE(addendum_contracts.total_value, 0)) <= ?", value.to_f)
        .pluck(:id)

      where(id: subquery)
    end
  }

  scope :by_active, lambda { |value| where("contracts.active = ?", value) if !value.nil? && !value.blank? }

  belongs_to :client, class_name: 'User', optional: true

  has_many :addendum_contracts, dependent: :destroy
  accepts_nested_attributes_for :addendum_contracts, :reject_if => proc { |attrs| attrs[:total_value].blank? }

  has_many :commitments, dependent: :destroy
  has_many :order_services, through: :commitments

  has_and_belongs_to_many :cost_centers, dependent: :destroy

  validates_presence_of :client_id, :name, :number, :total_value

  def get_text_name
    self.number.to_s
  end

  def get_total_value
    # Retorna 0 se o contrato estiver inativo
    return 0 unless self.active
    @total_value ||= self.total_value + self.addendum_contracts.select { |item| item.active }.sum(&:total_value)
  end

  def get_used_value(exclude_commitment_id = nil)
    commitments_query = self.commitments
    commitments_query = commitments_query.where.not(id: exclude_commitment_id) if exclude_commitment_id.present?
    
    # Valor dos empenhos
    commitment_values = commitments_query.sum(:commitment_value).to_f
    
    # Valor dos aditivos de empenho ativos
    addendum_values = AddendumCommitment
      .where(commitment_id: commitments_query.select(:id))
      .where(active: true)
      .sum(:total_value).to_f
    
    commitment_values + addendum_values
  end

  def get_disponible_value(exclude_commitment_id = nil)
    total_value = self.get_total_value
    used_value = self.get_used_value(exclude_commitment_id)
    
    Rails.logger.debug "=== get_disponible_value DEBUG ==="
    Rails.logger.debug "Contract ID: #{self.id}"
    Rails.logger.debug "Exclude Commitment ID: #{exclude_commitment_id}"
    Rails.logger.debug "Total Value: #{total_value}"
    Rails.logger.debug "Used Value: #{used_value}"
    Rails.logger.debug "Available: #{total_value - used_value}"
    
    return (total_value - used_value)
  end

	def total_value=(new_total_value)
		self[:total_value] = CustomHelper.currency_to_value(new_total_value)
	end

  def get_formatted_name
    return self.name.to_s + ' / ' + self.number.to_s + ' - ' + CustomHelper.to_currency(self.get_total_value)
  end

  def get_formatted_name_with_disponible_value
    return self.name.to_s + ' / ' + self.number.to_s + ' - Disponível: ' + CustomHelper.to_currency(self.get_disponible_value)
  end

  def self.getting_by_client_id(current_user, client_id)
    if current_user.admin?
      return Contract.by_client_id(client_id).order(:name)
    else
      return Contract.by_client_id(current_user.client_id).order(:name)
    end
  end

  private

  def default_values
    self.active = true if self.active.nil?
    self.name ||= ''
    self.number ||= ''
    self.total_value ||= 0
  end

end
