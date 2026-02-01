class CommitmentSerializer < ActiveModel::Serializer
  attributes :id, :commitment_number, :commitment_value
  has_one :client
  has_one :cost_center
  has_one :contract
end
