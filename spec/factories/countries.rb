FactoryBot.define do
	factory :country do
		name {Faker::Lorem.paragraph}
	end
end
