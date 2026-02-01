FactoryBot.define do
  factory :service_group do
    name { "MyString" }
    value_limit { "9.99" }
    active { false }
  end
end
