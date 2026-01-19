FactoryBot.define do
	factory :system_configuration do

		notification_mail {Faker::Internet.email}
		contact_mail {Faker::Internet.email}
		phone {Faker::Number.number(digits: 11)}
		use_policy {Faker::Lorem.sentence(word_count: 300)}
		privacy_policy {Faker::Lorem.sentence(word_count: 300)}
		about_product {Faker::Lorem.sentence(word_count: 300)}

		# notification_new_users {Faker::Internet.email}
		# notification_validation_users {Faker::Internet.email}

		# warranty_policy {Faker::Lorem.sentence(word_count: 300)}
		# exchange_policy {Faker::Lorem.sentence(word_count: 300)}

		# cellphone {Faker::Number.number(digits: 11)}
		# cnpj {Faker::CNPJ.pretty}

		# data_security_policy {Faker::Lorem.sentence(word_count: 300)}
		# quality {Faker::Lorem.sentence(word_count: 300)}
		# mission {Faker::Lorem.sentence(word_count: 300)}
		# view {Faker::Lorem.sentence(word_count: 300)}
		# values {Faker::Lorem.sentence(word_count: 300)}
		# about {Faker::Lorem.sentence(word_count: 300)}

		# about_video_link {Faker::Internet.url(host: 'youtube.com')}

		# site_link {Faker::Internet.url}
		# facebook_link {Faker::Internet.url(host: 'facebook.com')}
		# instagram_link {Faker::Internet.url(host: 'instagram.com')}
		# twitter_link {Faker::Internet.url(host: 'twitter.com')}
		# youtube_link {Faker::Internet.url(host: 'youtube.com')}

		# page_title {Faker::Lorem.paragraph}
		# page_description {Faker::Lorem.paragraph}

		# geral_conditions {Faker::Lorem.sentence(word_count: 300)}
		# contract_data {Faker::Lorem.sentence(word_count: 300)}

		# attendance_data {Faker::Lorem.sentence(word_count: 300)}
		# pix_limit_payment_minutes {20}

		after(:create) do |object|
			object.client_logo.attach(io: File.open("#{Rails.root}/app/assets/images/logos/logo.png"), filename: "logo.png")
			object.favicon.attach(io: File.open("#{Rails.root}/app/assets/images/favicon/favicon.png"), filename: "favicon.png")
			object.provider_contract.attach(io: File.open("#{Rails.root}/spec/support/files/arquivo.pdf"), filename: "arquivo.pdf")
		end

	end
end
