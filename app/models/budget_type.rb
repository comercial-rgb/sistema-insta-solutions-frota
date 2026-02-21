class BudgetType < ApplicationRecord
  after_initialize :default_values

  default_scope {
    order(:id)
  }

  MENSAL_ID = 1
  BIMESTRAL_ID = 2
  TRIMESTRAL_ID = 3
  SEMESTRAL_ID = 4
  ANUAL_ID = 5

  scope :by_id, lambda { |value| where("budget_types.id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(budget_types.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("budget_types.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("budget_types.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }


  def get_text_name
    self.id.to_s
  end

  private

  def default_values
  end

end
