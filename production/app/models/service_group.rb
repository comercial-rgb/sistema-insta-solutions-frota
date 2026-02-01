class ServiceGroup < ApplicationRecord
  audited
  
  after_initialize :default_values

  # Validations
  validates :name, presence: true

  # Associations
  has_many :order_services, dependent: :restrict_with_error
  has_many :service_group_items, dependent: :destroy
  has_many :services, through: :service_group_items
  
  accepts_nested_attributes_for :service_group_items, allow_destroy: true, reject_if: :all_blank

  # Scopes
  default_scope {
    order(:name)
  }

  scope :active, -> { where(active: true) }
  scope :by_id, lambda { |value| where("service_groups.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_name, lambda { |value| where("LOWER(service_groups.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  scope :by_active, lambda { |value| where("service_groups.active = ?", value) if !value.nil? && !value.blank? }
  scope :by_initial_date, lambda { |value| where("service_groups.created_at >= '#{value} 00:00:00'") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("service_groups.created_at <= '#{value} 23:59:59'") if !value.nil? && !value.blank? }

  def get_text_name
    self.name
  end

  private

  def default_values
    self.active = true if self.active.nil?
  end

end
