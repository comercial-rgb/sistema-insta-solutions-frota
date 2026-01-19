class Category < ApplicationRecord
	before_destroy :remove_vinculed_data
	validates_presence_of :name

	belongs_to :category_type, optional: true

	SERVICOS_PECAS_ID = 1
	SERVICOS_SERVICOS_ID = 2

	SERVICOS_PECAS = "pecas"
	SERVICOS_SERVICOS = "servicos"

	has_many :plans
	has_many :products
	has_many :services

	has_many :vehicles, dependent: :destroy

	has_many :sub_categories, validate: false, dependent: :destroy
	accepts_nested_attributes_for :sub_categories, :reject_if => proc { |attrs| attrs[:name].blank? }

	scope :by_name, lambda { |value| where("LOWER(categories.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
	scope :by_category_type_id, lambda { |value| where(category_type_id: value) if !value.nil? && !value.blank? }

	def as_json(options = {})
		{
			:id => self.id,
			:created_at => self.created_at,
			:updated_at => self.updated_at,
			:name => self.name,
			:category_type_id => self.category_type_id,
			:category_type => self.category_type,
			:sub_categories => self.sub_categories
		}
	end

	private

	def remove_vinculed_data
		self.plans.update_all(category_id: nil)
		self.products.update_all(category_id: nil)
		self.services.update_all(category_id: nil)
	end

end
