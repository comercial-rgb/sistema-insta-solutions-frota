FactoryBot.define do
  factory :site_contact do
    association :site_contact_subject
    association :user

    name {Faker::Name.name}
    email {Faker::Internet.email}
    phone {Faker::Number.number(digits: 11)}
    message {Faker::Lorem.paragraph}
  end
end
