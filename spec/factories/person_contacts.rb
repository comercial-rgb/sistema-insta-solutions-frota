FactoryBot.define do
  factory :person_contact do
    association :ownertable, factory: :country
    name {Faker::Name.name}
    email {Faker::Internet.email}
    phone {"(99) 99999-9999"}
    office {Faker::Lorem.sentence(word_count: 1)}
  end
end
