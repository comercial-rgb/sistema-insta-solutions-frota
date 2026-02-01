class ContractSerializer < ActiveModel::Serializer
  attributes :id, :name, :number, :total_value, :active
  has_one :client
end
