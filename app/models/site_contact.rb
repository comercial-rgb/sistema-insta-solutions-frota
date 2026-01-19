class SiteContact < ApplicationRecord
  after_initialize :default_values

  scope :by_id, lambda { |value| where("id = ?", value) if !value.nil? && !value.blank? }
  scope :by_site_contact_subject_id, lambda { |value| where("site_contact_subject_id = ?", value) if !value.nil? && !value.blank? }

  scope :by_name, lambda { |value| where("LOWER(site_contacts.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  scope :by_email, lambda { |value| where("LOWER(site_contacts.email) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("site_contacts.created_at >= '#{value} 00:00:00'") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("site_contacts.created_at <= '#{value} 23:59:59'") if !value.nil? && !value.blank? }

  belongs_to :site_contact_subject, optional: true
  belongs_to :user, optional: true

  validates_presence_of :name, :email, :phone, :message, :site_contact_subject_id
  
  def get_text_name
    self.id.to_s
  end

  private

  def default_values
  end

end
