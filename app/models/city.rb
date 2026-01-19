class City < ActiveRecord::Base
	after_initialize :default_values
	default_scope {order("cities.name").includes(:state)}
	
	belongs_to :state, optional: true
	belongs_to :country, optional: true
	has_many :addresses, dependent: :destroy

	validates_presence_of :name, :state_id, :country_id

	scope :by_name, lambda { |value| where("LOWER(cities.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
	scope :by_state_id, lambda { |value| where(state_id: value) if !value.nil? && !value.blank? }
	scope :by_country_id, lambda { |value| where("cities.country_id = ?", value) if !value.nil? && !value.blank? }

	def get_text_name
		return self.name
	end
	
	private

	def default_values
		self.name ||= ""
	end
end
