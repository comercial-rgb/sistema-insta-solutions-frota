FactoryBot.define do
	factory :category do
		association :category_type
		name {Faker::Lorem.sentence(word_count: 1)}

		after(:create) do |object|
			# FactoryBot.create_list(:sub_category, 5, category: object)
		end
	end
end
