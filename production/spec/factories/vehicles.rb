FactoryBot.define do
  factory :vehicle do
    association :client, factory: [:user, :client]
    cost_center { association :cost_center, :minimal, client: client }
    association :fuel_type
    association :vehicle_type
    association :city

    sequence(:board) { |n| "BRX#{n}#{SecureRandom.hex(1).upcase}" }
    brand { "Brand" }
    model { "Model" }
    year { 2020 }
    color { "Black" }
    renavam { Faker::Number.number(digits: 11).to_s }
    chassi { Faker::Number.number(digits: 11).to_s }
    market_value { 50_000 }
    acquisition_date { 1.year.ago.to_date }
    active { true }

    after(:build) do |vehicle|
      vehicle.state_id = vehicle.city.state_id if vehicle.city
    end
  end
end
