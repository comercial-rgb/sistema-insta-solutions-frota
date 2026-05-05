FactoryBot.define do
  factory :address do
    association :ownertable, factory: :country
    association :city
    association :address_type
    association :address_area

    remove_validate { true }

    name { Faker::Lorem.words(number: 2).join(" ") }
    zipcode { "01310100" }
    address { Faker::Address.street_address }
    district { Faker::Address.street_name }
    number { Faker::Number.number(digits: 3).to_s }
    complement { "Apto 1" }
    reference { "Ref" }

    after(:build) do |addr|
      next unless addr.city

      addr.state_id = addr.city.state_id
      addr.country_id = addr.city.state&.country_id
    end
  end
end
