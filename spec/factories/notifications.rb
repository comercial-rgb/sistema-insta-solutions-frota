FactoryBot.define do
  factory :notification do
    profile { nil }
    send_all { false }
    title { "MyString" }
    message { "MyText" }
  end
end
