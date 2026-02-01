FactoryBot.define do
  factory :order_service_proposal do
    order_service { nil }
    provider { nil }
    order_service_proposal_status { nil }
    details { "MyText" }
    total_value { "9.99" }
    total_discount { "9.99" }
    total_value_without_discount { "9.99" }
  end
end
