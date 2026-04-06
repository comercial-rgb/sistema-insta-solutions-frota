class NotificationAcknowledgment < ApplicationRecord
  belongs_to :notification
  belongs_to :user

  validates :notification_id, uniqueness: { scope: :user_id }
  validates :acknowledged_at, presence: true
end
