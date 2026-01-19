FactoryBot.define do
  factory :provider_service_temp do
    order_service_proposal { nil }
    name { "MyString" }
    code { "MyString" }
    price { "9.99" }
    category { nil }
    description { "MyText" }
    quantity { 1 }
    discount { "9.99" }
    total_value { "9.99" }
  end
end
