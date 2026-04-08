class SupportTicketMessage < ApplicationRecord
  default_scope {
    includes(:user)
    .order(created_at: :asc)
  }

  belongs_to :support_ticket
  belongs_to :user

  has_many :attachments, as: :ownertable, validate: false, dependent: :destroy
  accepts_nested_attributes_for :attachments, reject_if: :all_blank

  validates_presence_of :message, :user_id, :support_ticket_id
end
