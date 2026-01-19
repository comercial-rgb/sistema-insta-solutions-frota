FactoryBot.define do
  factory :order_service do
    created_at {Faker::Date.between(from: 1.years.ago, to: 1.months.ago)}
    updated_at {Faker::Date.between(from: 1.years.ago, to: 1.months.ago)}
    order_service_status_id { OrderServiceStatus.all.map(&:id).sample }
    client_id { User.client.map(&:id).sample }
    manager_id { User.manager.map(&:id).sample }
    vehicle_id { Vehicle.all.map(&:id).sample }
    provider_service_type_id { ProviderServiceType.all.map(&:id).sample }
    maintenance_plan_id { MaintenancePlan.all.map(&:id).sample }
    order_service_type_id { OrderServiceType.all.map(&:id).sample }
    # provider_id { User.provider.map(&:id).sample }
    km {rand(1000..10000)}
    driver {Faker::Name.name}
    details {Faker::Lorem.sentence(word_count: 30)}
    cancel_justification {Faker::Lorem.sentence(word_count: 15)}
    invoice_information {Faker::Lorem.sentence(word_count: 15)}

    invoice_part_ir {1.2}
    invoice_part_pis {0.65}
    invoice_part_cofins {3}
    invoice_part_csll {1}
    invoice_service_ir {4.8}
    invoice_service_pis {0.65}
    invoice_service_cofins {3}
    invoice_service_csll {1}
  end
end
