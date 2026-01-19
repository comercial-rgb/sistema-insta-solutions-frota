FactoryBot.define do
  factory :addendum_contract do
    contract { Contract.order("RAND()").first }
    name {Faker::Lorem.sentence(word_count: 1)}
    number {Faker::Number.number(digits: 7)}
    total_value {Faker::Commerce.price(range: 10000..20000)}
    active {1}
  end
end
