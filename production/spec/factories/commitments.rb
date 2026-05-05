FactoryBot.define do
  factory :commitment do
    association :client, factory: [:user, :client]
    cost_center { association :cost_center, :minimal, client: client }
    contract { association :contract, :minimal, client: client }
    commitment_number { "EMP-#{SecureRandom.hex(3)}" }
    commitment_value { 10_000 }

    after(:create) do |commitment|
      CommitmentCostCenter.find_or_create_by!(
        commitment: commitment,
        cost_center: commitment.cost_center
      )
    end

    trait :with_multiple_cost_centers do
      after(:create) do |commitment|
        CostCenter.where(client_id: commitment.client_id).limit(3).each do |cc|
          CommitmentCostCenter.find_or_create_by!(commitment: commitment, cost_center: cc)
        end
      end
    end
  end
end
