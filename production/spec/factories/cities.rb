FactoryBot.define do
  factory :city do
    name { Faker::Address.city }
    latitude { -23.5 }
    longitude { -46.6 }
    association :state
    ibge_code { Faker::Number.number(digits: 5).to_s }
    quantity_population { 1_000_000 }

    after(:build) do |city|
      city.country_id = city.state.country_id if city.state
    end
  end
end
