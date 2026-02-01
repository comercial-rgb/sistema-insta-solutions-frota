class OrderServiceProposalSerializer < ActiveModel::Serializer
  attributes :id, :details, :total_value, :total_discount, :total_value_without_discount
  has_one :order_service
  has_one :provider
  has_one :order_service_proposal_status
end
