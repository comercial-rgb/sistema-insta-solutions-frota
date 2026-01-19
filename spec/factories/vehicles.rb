FactoryBot.define do
  factory :vehicle do
    client { User.client.order("RAND()").first }
    cost_center { CostCenter.all.order("RAND()").first }
    sub_unit { SubUnit.all.order("RAND()").first }
    board { (('a'..'z').to_a.sample(3).join + (0..9).to_a.sample(4).join).upcase }
    brand {Faker::Lorem.sentence(word_count: 1)}
    model {Faker::Lorem.sentence(word_count: 1)}
    year { rand(1990..2024) }
    color { Faker::Color.color_name }
    renavam {Faker::Number.number(digits: 11)}
    chassi {Faker::Number.number(digits: 11)}
    market_value {Faker::Commerce.price(range: 10000..200000)}
    acquisition_date {Faker::Date.between(from: 2.years.ago, to: 1.years.ago)}
    vehicle_type { VehicleType.all.order("RAND()").first }
    category { Category.by_category_type_id(CategoryType::VEICULOS_ID).order("RAND()").first }
    state_id {13}
    city_id {rand(1597..2449)}
    fuel_type { FuelType.all.order("RAND()").first }
    active { rand(0..1) }
  end
end
