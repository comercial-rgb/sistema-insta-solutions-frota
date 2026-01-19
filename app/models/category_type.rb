class CategoryType < ApplicationRecord
  after_initialize :default_values

  PLANOS_ID = 1
  PRODUTOS_ID = 2
  SERVICOS_ID = 3
  VEICULOS_ID = 4

  PLANOS_NAME = Category.human_attribute_name(:plans)
  PRODUTOS_NAME = Category.human_attribute_name(:products)
  SERVICOS_NAME = Category.human_attribute_name(:services)
  VEICULOS_NAME = Category.human_attribute_name(:vehicles)

  scope :by_id, lambda { |value| where("id = ?", value) if !value.nil? && !value.blank? }
  has_many :categories

  def get_text_name
    self.name
  end

  def self.get_name_by_id(category_type_id)
    value = category_type_id.to_i unless category_type_id.nil?
    case value
    when CategoryType::PLANOS_ID
      return CategoryType::PLANOS_NAME
    when CategoryType::PRODUTOS_ID
      return CategoryType::PRODUTOS_NAME
    when CategoryType::SERVICOS_ID
      return CategoryType::SERVICOS_NAME
    when CategoryType::VEICULOS_ID
      return CategoryType::VEICULOS_NAME
    else
      return Category.human_attribute_name(:no_information)
    end
  end

  def as_json(options = {})
    {
      :id => self.id,
      :name => self.name
    }
  end

  def get_text_name
    self.name.to_s
  end

  private

  def default_values
  end

end
