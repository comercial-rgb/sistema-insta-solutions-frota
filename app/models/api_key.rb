class ApiKey < ApplicationRecord
  belongs_to :user

  before_create :generate_access_token

  scope :active, -> { where('expires_at > ? OR expires_at IS NULL', DateTime.now) }

  def expired?
    expires_at.present? && expires_at < DateTime.now
  end

  private

  def generate_access_token
    self.access_token = SecureRandom.hex if access_token.blank?
  end
end
