class Country < ActiveRecord::Base
	after_initialize :default_values

	default_scope {order("countries.name")}

	has_many :states, dependent: :destroy
	has_many :cities, dependent: :destroy
	
	validates_presence_of :name

	scope :by_name, lambda { |value| where("LOWER(countries.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

	def get_text_name
		return self.name
	end

	private

	def default_values
		self.name ||= ""
	end
end
