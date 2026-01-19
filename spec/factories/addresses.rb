FactoryBot.define do
    factory :address do
        association :ownertable, factory: :country
        country_id {33}
        state_id {13}
        city_id {rand(1597..2449)}
        address_type_id {rand(1..44)}
        address_area_id {1}

        name {Faker::Lorem.sentence(word_count: 2)}
        zipcode {Faker::Address.zip_code}
        address {Faker::Address.street_address}
        district {Faker::Address.street_name}
        number {Faker::Number.number(digits: 3)}
        complement {Faker::Address.secondary_address}
        reference {Faker::Lorem.paragraph}
        remove_validate {true}

        after(:create) do |object|
            # city = City.where(state_id: object.state_id).order("RAND()").limit(1).first
            # if city
            #     object.update_columns(city_id: city.id)
            # end
        end
    end
end
