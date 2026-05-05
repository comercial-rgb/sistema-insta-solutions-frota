FactoryBot.define do
  factory :vehicle_type do
    name { "Tipo #{SecureRandom.hex(2)}" }
  end
end
