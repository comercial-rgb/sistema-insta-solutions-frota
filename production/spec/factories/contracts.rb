FactoryBot.define do
  factory :contract do
    client { User.client.order("RAND()").first }
    name {Faker::Lorem.sentence(word_count: 1)}
    number {Faker::Number.number(digits: 7)}
    initial_date {Faker::Date.between(from: 2.years.ago, to: 1.years.ago)}
    total_value {Faker::Commerce.price(range: 10000..20000)}
    active {1}

    after(:create) do |object|
      create_list(:addendum_contract, 3, contract: object)
    end
  end
end
