FactoryBot.define do
	factory :user do

		profile_id {2}
		user_status_id {UserStatus::APROVADO_ID}

		new_user {true}
		seed {true}
		accept_therm {true}
		is_blocked {false}
		external_register {false}
		validated_mail {true}

		name {Faker::Name.name}
		email {Faker::Internet.email}
		# access_user {Faker::IDNumber.valid}
		password {Faker::Internet.password}
		recovery_token {SecureRandom.urlsafe_base64}
		validate_mail_token {SecureRandom.urlsafe_base64}
		cpf {Faker::CPF.pretty}
		rg {Faker::Number.number(digits: 7)}
		birthday {Faker::Date.between(from: 30.years.ago, to: 19.years.ago)}
		phone {"(99) 99999-9999"}
		cellphone {"(99) 99999-9999"}

		cnpj {Faker::CNPJ.pretty}
		social_name {Faker::Company.name}
		fantasy_name {Faker::Company.name}

		municipal_inscription {Faker::Number.number(digits: 6)}
		state_inscription {Faker::Number.number(digits: 6)}
		discount_percent {Faker::Number.number(digits: 1)}
		department {Faker::Lorem.sentence(word_count: 1)}
		state_id {13}
    city_id {rand(1597..2449)}

		client_id { User.client.map(&:id).sample }

		registration {Faker::Number.number(digits: 6)}

		after(:create) do |object|
			object.profile_image.attach(io: File.open("#{Rails.root}/spec/support/files/perfil.png"), filename: "perfil.png")
			FactoryBot.create(:address, ownertable: object)
			if object.provider?
				ProviderServiceType.all.each do |provider_service_type|
					object.provider_service_types << provider_service_type
				end
			end
			if object.client?
				state = State.find(13)
				object.states << state
			end
		end

	end
end
