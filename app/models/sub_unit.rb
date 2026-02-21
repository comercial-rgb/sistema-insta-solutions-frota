class SubUnit < ApplicationRecord
  after_initialize :default_values

  default_scope {
    order(:id)
  }

  scope :by_id, lambda { |value| where("sub_units.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_cost_center_ids, lambda { |value| joins(:cost_center).where("cost_centers.id IN (?)", value) if !value.nil? }
  scope :by_client_id, lambda { |value| joins(:cost_center).where("cost_centers.client_id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(sub_units.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("sub_units.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("sub_units.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

  scope :by_cost_center_or_sub_unit_ids, lambda { |cost_center_ids, sub_unit_ids|
    if cost_center_ids.present? || sub_unit_ids.present?
      where(
        arel_table[:cost_center_id].in(Array(cost_center_ids)).
        or(arel_table[:id].in(Array(sub_unit_ids)))
      )
    end
  }

  belongs_to :cost_center, optional: true
  belongs_to :budget_type, optional: true

  has_many :vehicles, dependent: :destroy

  def get_text_name
    self.name.to_s
  end

  def initial_consumed_balance=(new_initial_consumed_balance)
		self[:initial_consumed_balance] = CustomHelper.currency_to_value(new_initial_consumed_balance)
	end

  def budget_value=(new_budget_value)
		self[:budget_value] = CustomHelper.currency_to_value(new_budget_value)
	end

  def self.getting_data_by_user(current_user, client_id)
    if current_user.manager? || current_user.additional?
      client_id = current_user.client_id
      cost_center_ids = current_user.associated_cost_centers.map(&:id)
      sub_unit_ids = current_user.associated_sub_units.map(&:id)
    end
    result = []
    if current_user.admin?
      result = SubUnit.by_client_id(client_id).order(:name)
    elsif current_user.manager?
      result = SubUnit.by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids).order(:name)
    elsif current_user.additional?
      result = SubUnit.by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids).order(:name)
    end
    return result
  end

  private

  def default_values
    self.name ||= ""
  end

end
