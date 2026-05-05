class PersonContact < ApplicationRecord
  after_initialize :default_values

  default_scope {
    order(:name)
  }

  scope :by_id, lambda { |value| where("person_contacts.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_name, lambda { |value| where("LOWER(person_contacts.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("person_contacts.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("person_contacts.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

  belongs_to :ownertable, :polymorphic => true, optional: true

  validates_presence_of :ownertable_id

  def get_text_name
    self.name.to_s
  end

  private

  def default_values
    self.name ||= ""
    self.email ||= ""
    self.phone ||= ""
    self.office ||= ""
  end

end
