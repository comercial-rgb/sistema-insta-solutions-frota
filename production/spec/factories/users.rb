FactoryBot.define do
  factory :user do
    profile_id { Profile::ADMIN_ID }
    user_status_id { UserStatus::APROVADO_ID }

    new_user { true }
    seed { true }
    accept_therm { true }
    is_blocked { false }
    external_register { false }
    validated_mail { true }

    name { "#{Faker::Name.first_name} #{Faker::Name.last_name}" }
    email { "#{SecureRandom.hex(6)}@example.test" }
    password { "TestPass123!" }
    password_confirmation { "TestPass123!" }
    recovery_token { SecureRandom.urlsafe_base64 }
    validate_mail_token { SecureRandom.urlsafe_base64 }
    cpf { Faker::CPF.pretty }
    rg { Faker::Number.number(digits: 7).to_s }
    birthday { Faker::Date.between(from: 30.years.ago, to: 19.years.ago) }
    phone { "(99) 99999-9999" }
    cellphone { "(99) 99999-9999" }

    cnpj { Faker::CNPJ.pretty }
    social_name { Faker::Company.name }
    fantasy_name { Faker::Company.name }

    municipal_inscription { Faker::Number.number(digits: 6).to_s }
    state_inscription { Faker::Number.number(digits: 6).to_s }
    discount_percent { 0 }
    department { "Dept" }
    client_id { nil }
    registration { Faker::Number.number(digits: 6).to_s }

    association :city

    after(:build) do |user|
      user.state_id = user.city.state_id if user.city
    end

    trait :client do
      profile_id { Profile::CLIENT_ID }
    end

    after(:create) do |user|
      logo = Rails.root.join("app/assets/images/logos/logo-sulivam-softwares.png")
      if File.exist?(logo)
        user.profile_image.attach(io: File.open(logo), filename: "logo.png")
      end
      unless user.address.present?
        FactoryBot.create(:address, ownertable: user)
      end
      if user.provider?
        ProviderServiceType.find_each do |provider_service_type|
          user.provider_service_types << provider_service_type
        end
      end
      if user.client?
        state = user.city&.state || State.first
        user.states << state if state && !user.state_ids.include?(state.id)
      end
    end
  end
end
