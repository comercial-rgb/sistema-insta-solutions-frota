class NotificationSerializer < ActiveModel::Serializer
  attributes :id, :send_all, :title, :message
  has_one :profile
end
