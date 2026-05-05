FactoryBot.define do
  factory :contract do
    transient do
      with_addenda { true }
    end

    association :client, factory: [:user, :client]
    name { "Contrato #{SecureRandom.hex(2)}" }
    number { Faker::Number.number(digits: 7).to_s }
    initial_date { 2.years.ago.to_date }
    total_value { 50_000 }
    active { 1 }

    trait :minimal do
      with_addenda { false }
    end

    after(:create) do |object, evaluator|
      next unless evaluator.with_addenda

      create_list(:addendum_contract, 1, contract: object)
    end
  end
end
