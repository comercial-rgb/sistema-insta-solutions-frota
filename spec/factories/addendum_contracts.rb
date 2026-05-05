FactoryBot.define do
  factory :addendum_contract do
    association :contract
    name { Faker::Lorem.word }
    number { Faker::Number.number(digits: 7).to_s }
    total_value { 10_000 }
    active { 1 }
  end
end
