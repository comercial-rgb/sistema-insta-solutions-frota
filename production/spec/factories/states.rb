FactoryBot.define do
	factory :state do
		name {Faker::Address.state}
		acronym {Faker::Address.state_abbr}
		ibge_code {Faker::Number.number(digits: 2)}
		association :country
	end
end
