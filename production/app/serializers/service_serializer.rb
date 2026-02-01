class ServiceSerializer < ActiveModel::Serializer
  attributes :id, :name, :image, :description, :price
  has_one :category
end
