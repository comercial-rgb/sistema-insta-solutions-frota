FactoryBot.define do
  factory :cancel_commitment do
    commitment { nil }
    value { "9.99" }
    number { "MyString" }
    date { "2025-01-27" }
  end
end
