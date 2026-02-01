FactoryBot.define do
  factory :order_service_invoice do
    order_service_proposal { nil }
    order_service_invoice_type { nil }
    number { "MyString" }
    value { "9.99" }
    emission_date { "2024-08-22" }
  end
end
