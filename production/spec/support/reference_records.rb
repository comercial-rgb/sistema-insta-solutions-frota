# frozen_string_literal: true

# Minimal rows required by FK defaults on User and by factories/specs.
RSpec.configure do |config|
  config.before(:suite) do
    next unless ActiveRecord::Base.connection.data_source_exists?("profiles")

    Profile.find_or_create_by!(id: Profile::ADMIN_ID) { |p| p.name = Profile::ADMIN }
    Profile.find_or_create_by!(id: Profile::USER_ID) { |p| p.name = Profile::USER }
    Profile.find_or_create_by!(id: Profile::CLIENT_ID) { |p| p.name = Profile::CLIENT }
    Profile.find_or_create_by!(id: Profile::MANAGER_ID) { |p| p.name = Profile::MANAGER }
    Profile.find_or_create_by!(id: Profile::ADDITIONAL_ID) { |p| p.name = Profile::ADDITIONAL }
    Profile.find_or_create_by!(id: Profile::PROVIDER_ID) { |p| p.name = Profile::PROVIDER }
    Profile.find_or_create_by!(id: Profile::DRIVER_ID) { |p| p.name = Profile::DRIVER }

    UserStatus.find_or_create_by!(id: UserStatus::AGUARDANDO_AVALIACAO_ID) { |s| s.name = "Aguardando" }
    UserStatus.find_or_create_by!(id: UserStatus::APROVADO_ID) { |s| s.name = "Aprovado" }
    UserStatus.find_or_create_by!(id: UserStatus::REPROVADO_ID) { |s| s.name = "Reprovado" }

    PersonType.find_or_create_by!(id: PersonType::FISICA_ID) { |p| p.name = PersonType::FISICA }
    PersonType.find_or_create_by!(id: PersonType::JURIDICA_ID) { |p| p.name = PersonType::JURIDICA }

    Sex.find_or_create_by!(id: Sex::MASCULINO_ID) { |s| s.name = "Masculino" }
    Sex.find_or_create_by!(id: Sex::FEMININO_ID) { |s| s.name = "Feminino" }
    Sex.find_or_create_by!(id: Sex::NAO_QUERO_INFORMAR_ID) { |s| s.name = "Não informar" }
  end
end
