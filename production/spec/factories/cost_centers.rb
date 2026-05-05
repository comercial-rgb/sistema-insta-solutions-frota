FactoryBot.define do
  factory :cost_center do
    transient do
      full_fixtures { true }
    end

    association :client, factory: [:user, :client]
    association :budget_type
    name { Faker::Company.name }
    contract_number { Faker::Number.number(digits: 6).to_s }
    commitment_number { Faker::Number.number(digits: 6).to_s }
    initial_consumed_balance { 0 }
    description { "CC test" }
    budget_value { 100_000 }
    contract_initial_date { 2.years.ago.to_date }
    has_sub_units { false }

    invoice_name { Faker::Company.name }
    invoice_cnpj { Faker::CNPJ.pretty }
    invoice_address { Faker::Address.street_address }
    association :invoice_state, factory: :state
    invoice_fantasy_name { Faker::Company.name }

    trait :minimal do
      full_fixtures { false }
    end

    after(:create) do |object, evaluator|
      next unless evaluator.full_fixtures

      FactoryBot.create_list(:sub_unit, 2, cost_center_id: object.id)
    end
  end
end
