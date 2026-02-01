class State < ActiveRecord::Base
	after_initialize :default_values

	belongs_to :country, optional: true
	has_many :cities, dependent: :destroy
	has_many :addresses, dependent: :destroy

	default_scope {order("states.name")}

	scope :by_country_id, lambda { |value| where("country_id = ?", value) if !value.nil? && !value.blank? }
	scope :by_name, lambda { |value| where("LOWER(states.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

	validates_presence_of :name, :acronym

	def get_text_name
		return self.name
	end

	private

	def default_values
		self.name ||= ""
	end
end
