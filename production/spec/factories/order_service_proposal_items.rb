FactoryBot.define do
  factory :order_service_proposal_item do
    order_service_proposal { nil }
    service { nil }
    quantity { 1 }
    discount { "9.99" }
    total_value { "9.99" }
  end
end
