class CancelCommitment < ApplicationRecord
  after_initialize :default_values

  default_scope {
    order(:id)
  }

  scope :by_id, lambda { |value| where("cancel_commitments.id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(cancel_commitments.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("cancel_commitments.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("cancel_commitments.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

  belongs_to :commitment, optional: true

  validates_presence_of :commitment_id, :value, :number

  def value=(new_value)
		self[:value] = CustomHelper.currency_to_value(new_value)
	end

  def get_text_name
    self.id.to_s
  end

  private

  def default_values
    self.value ||= 0
    self.date ||= Date.today
  end

end
