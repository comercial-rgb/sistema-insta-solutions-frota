class FuelType < ApplicationRecord
  after_initialize :default_values

  default_scope {
    order(:id)
  }

  scope :by_id, lambda { |value| where("fuel_types.id = ?", value) if !value.nil? && !value.blank? }
  # scope :by_name, lambda { |value| where("LOWER(fuel_types.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("fuel_types.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("fuel_types.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

  validates_presence_of :name

  def get_text_name
    self.id.to_s
  end

  private

  def default_values
  end

end
