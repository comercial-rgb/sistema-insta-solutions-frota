FactoryBot.define do
	factory :person_type do
		name {Faker::Lorem.paragraph}
	end
end
