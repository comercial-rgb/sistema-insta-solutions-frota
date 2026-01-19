FactoryBot.define do
  factory :vehicle_type do
    name {Faker::Lorem.sentence(word_count: 2)}
  end
end
