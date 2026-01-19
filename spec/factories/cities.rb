FactoryBot.define do
	factory :city do
		name {Faker::Address.city}
		latitude {Faker::Number.number(digits: 10)}
		longitude {Faker::Number.number(digits: 10)}
		association :state
		ibge_code {Faker::Number.number(digits: 5)}
		quantity_population {Faker::Number.number(digits: 5)}
	end
end
