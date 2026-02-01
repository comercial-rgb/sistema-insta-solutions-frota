class ProviderServiceType < ApplicationRecord
  after_initialize :default_values

  default_scope {
    order(:name)
  }

  scope :by_id, lambda { |value| where("provider_service_types.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_name, lambda { |value| where("LOWER(provider_service_types.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("provider_service_types.created_at >= '#{value} 00:00:00'") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("provider_service_types.created_at <= '#{value} 23:59:59'") if !value.nil? && !value.blank? }

  validates_presence_of :name

  def get_text_name
    display_name
  end

  def display_name
    name.to_s.force_encoding('UTF-8')
  end

  private

  def default_values
    self.name ||= ""
    self.description ||= ""
  end

end
