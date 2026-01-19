require 'uri'
FactoryBot.define do
	factory :attachment do
		association :ownertable, factory: :country
		attachment_type {Faker::Number.number(digits: 1)}
		after(:create) do |object|
			object.attachment.attach(io: File.open("#{Rails.root}/app/assets/images/logos/logo-sulivam-softwares.png"), filename: "logo-sulivam-softwares.png")
		end
	end
end
