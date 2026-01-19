FactoryBot.define do
  factory :commitment do
    client { User.client.order("RAND()").first }
    cost_center_id { CostCenter.all.map(&:id).sample } # Mantido para compatibilidade
    contract_id { Contract.all.map(&:id).sample }
    commitment_number { Faker::Number.number(digits: 6) }
    commitment_value { Faker::Commerce.price(range: 10000..20000) }
    
    # Trait para criar empenho com múltiplos centros de custo
    trait :with_multiple_cost_centers do
      after(:create) do |commitment|
        cost_centers = CostCenter.all.sample(rand(2..3))
        cost_centers.each do |cc|
          CommitmentCostCenter.find_or_create_by!(commitment: commitment, cost_center: cc)
        end
      end
    end
  end
end
