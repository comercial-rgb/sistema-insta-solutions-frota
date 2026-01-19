FactoryBot.define do
	factory :profile do
		name {Faker::Lorem.paragraph}
	end
end
