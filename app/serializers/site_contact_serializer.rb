class SiteContactSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :phone, :message
  has_one :site_contact_subject
  has_one :user
end
