FactoryBot.define do
  factory :provider_service_type do
    name {Faker::Lorem.sentence(word_count: 1)}
    description {Faker::Lorem.sentence(word_count: 5)}
  end
end
