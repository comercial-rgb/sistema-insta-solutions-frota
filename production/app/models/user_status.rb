class UserStatus < ApplicationRecord
  after_initialize :default_values

  AGUARDANDO_AVALIACAO_ID = 1
  APROVADO_ID = 2
  REPROVADO_ID = 3

  default_scope {
    order(:id)
  }

  scope :by_id, lambda { |value| where("user_statuses.id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(user_statuses.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  
  scope :by_initial_date, lambda { |value| where("user_statuses.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("user_statuses.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }
  
  def get_text_name
    self.id.to_s
  end

  private

  def default_values
  end

end
