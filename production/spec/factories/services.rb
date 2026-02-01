FactoryBot.define do
  factory :service do
    provider_id {User.provider.map(&:id).sample}
    category_id {Category.by_category_type_id(CategoryType::SERVICOS_ID).map(&:id).sample}
    name {Faker::Commerce.product_name}
    code {Faker::Commerce.promotion_code}
    description {Faker::Lorem.paragraph}
    price {Faker::Commerce.price}
    warranty_period {Faker::Number.number(digits: 2)}
    brand {Faker::Commerce.brand}

    after(:create) do |object|
    end

  end
end
