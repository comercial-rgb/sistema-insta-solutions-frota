class OrientationManual < ApplicationRecord
  after_initialize :default_values

  default_scope {
    order(:name)
  }

  scope :by_id, lambda { |value| where("orientation_manuals.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_profile_id, lambda { |value| joins(:profiles).where("profiles.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_name, lambda { |value| where("LOWER(orientation_manuals.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  scope :by_description, lambda { |value| where("LOWER(orientation_manuals.description) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("orientation_manuals.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("orientation_manuals.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

  has_and_belongs_to_many :profiles, dependent: :destroy

  validates_presence_of :name, :description

  has_one_attached :document

  def get_text_name
    self.name.to_s
  end

  private

  def default_values
    self.name ||= ""
    self.description ||= ""
  end

end
