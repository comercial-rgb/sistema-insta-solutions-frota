FactoryBot.define do
  factory :cost_center do
    client { User.client.order("RAND()").first }
    name {Faker::Lorem.sentence(word_count: 2)}
    contract_number {Faker::Number.number(digits: 6)}
    commitment_number {Faker::Number.number(digits: 6)}
    initial_consumed_balance {Faker::Commerce.price}
    description {Faker::Lorem.sentence(word_count: 5)}
    budget_value {Faker::Commerce.price}
    budget_type_id {rand(1..5)}
    contract_initial_date {Faker::Date.between(from: 2.years.ago, to: 1.years.ago)}
    has_sub_units { rand(0..1) }

    invoice_name {Faker::Lorem.sentence(word_count: 1)}
    invoice_cnpj {Faker::CNPJ.pretty}
    invoice_address {Faker::Lorem.sentence(word_count: 5)}
    invoice_state_id {13}
    invoice_fantasy_name {Faker::Company.name}

    after(:create) do |object|
      FactoryBot.create_list(:sub_unit, 2, cost_center_id: object.id)
      contracts = Contract.by_client_id(object.client_id).order("RAND()").limit(2)
      object.contracts << contracts
      contracts.each do |contract|
        disponible_value = contract.get_disponible_value
        FactoryBot.create(:commitment, cost_center_id: object.id, contract_id: contract.id, commitment_value: disponible_value)
      end
    end
  end
end
