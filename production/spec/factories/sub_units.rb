FactoryBot.define do
  factory :sub_unit do
    cost_center { nil }
    name {Faker::Lorem.sentence(word_count: 2)}
    contract_number {Faker::Number.number(digits: 6)}
    commitment_number {Faker::Number.number(digits: 6)}
    initial_consumed_balance {Faker::Commerce.price}
    budget_value {Faker::Commerce.price}
    budget_type_id {rand(1..5)}
    contract_initial_date {Faker::Date.between(from: 2.years.ago, to: 1.years.ago)}
  end
end
