class ServiceGroupClient < ApplicationRecord
  # Validations
  validates :service_group_id, presence: true
  validates :client_id, presence: true
  validates :client_id, uniqueness: { scope: :service_group_id, message: "já está associado a este grupo" }

  # Associations
  belongs_to :service_group
  belongs_to :client, class_name: 'User', foreign_key: 'client_id'

  def get_text_name
    "#{service_group.name} - #{client.get_name}"
  end
end
