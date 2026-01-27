class Address < ActiveRecord::Base
	after_initialize :default_values

	attr_accessor :complete_address, :city_name, :state_name, :remove_validate, :validate_to_order, :page_title

	GOOGLE_ZERO_RESULTS = "ZERO_RESULTS"

	belongs_to :ownertable, :polymorphic => true, optional: true
	belongs_to :state, optional: true
	belongs_to :city, optional: true
	belongs_to :country, optional: true
	belongs_to :address_type, optional: true
	belongs_to :address_area, optional: true

	validates_presence_of :zipcode, :address, :district, :number, :state_id, :city_id, if: Proc.new { |item| item.remove_validate != true }

	scope :by_name, lambda { |value| where("LOWER(addresses.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

	scope :by_ownertable_type, lambda { |value| where(ownertable_type: value) if !value.nil? && !value.blank? }
	scope :by_ownertable_id, lambda { |value| where(ownertable_id: value) if !value.nil? && !value.blank? }
	scope :by_address_area_id, lambda { |value| where(address_area_id: value) if !value.nil? && !value.blank? }
	scope :by_address_area_ids, lambda { |values| where(address_area_id: [values]) if !values.nil? && values.length > 0 }

	def as_json(options = {})
		{
			:id => self.id,
			:name => self.name,
			:complete_address => self.get_address_value,
			:address => self.address,
			:number => self.number,
			:complement => self.complement,
			:district => self.district,
			:city_id => self.city_id,
			:city => (self.city.name unless self.city.nil?),
			:state_id => self.state_id,
			:state => (self.state.name unless self.state.nil?),
			:zipcode => self.zipcode,
			:reference => self.reference,
			:address_type_id => self.address_type_id,
			:address_type => (self.address_type.name unless self.address_type.nil?)
		}
	end

	def get_address_value
		text = ""
		if self.address != nil && self.address != ''
			text += self.address
		end
		if self.number != nil && self.number != ''
			text += ', '+self.number
		end
		if self.complement != nil && self.complement != ''
			text += ', '+self.complement
		end
		if self.district != nil && self.district != ''
			text += ', '+self.district
		end
		if self.city_id != nil && self.city_id != ''
			text += ', '+self.city.name
		end
		if self.state_id != nil && self.state_id != ''
			text += '/'+self.state.acronym
		end
		if self.zipcode != nil && self.zipcode != ''
			text += ' - '+Address.human_attribute_name(:zipcode)+" "+self.zipcode
		end
		return text
	end

	def get_address_value_until_district
		text = ""
		if self.address != nil && self.address != ''
			text += self.address
		end
		if self.number != nil && self.number != ''
			text += ', '+self.number
		end
		if self.complement != nil && self.complement != ''
			text += ', '+self.complement
		end
		if self.district != nil && self.district != ''
			text += ', '+self.district
		end
		return text
	end

	def get_address_value_city_zipcode
		text = ""
		if self.city_id != nil && self.city_id != ''
			text += self.city.name
		end
		if self.state_id != nil && self.state_id != ''
			text += ', '+self.state.name
		end
		if self.zipcode != nil && self.zipcode != ''
			text += ', '+self.zipcode
		end
		return text
	end

	def safe_district
		district.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
	end

	def get_city_and_state
		text = ''
		if !self.city.nil?
			text += self.city.name
		end
		if !self.state.nil?
			text += '/'+self.state.name
		end
		return text
	end

	def get_complete_address_google
		text = ""
		if self.address != nil && self.address != ''
			text += self.address
		end
		if self.number != nil && self.number != ''
			text += ','+self.number
		end
		if self.district != nil && self.district != ''
			text += ', '+self.district
		end
		if self.city_id != nil && self.city_id != ''
			text += ','+self.city.name
		end
		if self.state_id != nil && self.state_id != ''
			text += ','+self.state.name
		end
		return text.gsub(" ","%20")
	end

	# <iframe
    #     allowfullscreen
    #     width="100%"
    #     height="300"
    #     frameborder="0" style="border:0"
    #     src="https://www.google.com/maps/embed/v1/place?key=<%= ENV["GOOGLE_MAPS_API"] %>&q=<%=address.get_complete_address_google%>">
    # </iframe>

    # Buscando latitude e longitude pelo Google
	def self.getting_latitude_longitude(address)
		begin
			if (address.latitude.nil? || address.longitude.nil?) || (address.latitude.blank? || address.longitude.blank?)
				service = Utils::Google::GoogleGetLatLngService.new(address.get_address_value)
				result = service.call
				if result[0]
					result_address = result[1][0]
					if !result_address[:geometry].nil? && !result_address[:geometry][:location].nil?
						location = result_address[:geometry][:location]
						if !location.nil?
							latitude = location[:lat]
							longitude = location[:lng]
							address.update_columns(latitude: latitude, longitude: longitude)
						end
					end
				end
			end
		rescue Exception => e
			Rails.logger.error e.message
			Rails.logger.error "-- getting_latitude_longitude --"
		end
	end
	
	private

	def default_values
		self.name ||= '' if self.has_attribute?(:name)
		self.zipcode ||= '' if self.has_attribute?(:zipcode)
		self.address ||= '' if self.has_attribute?(:address)
		self.district ||= '' if self.has_attribute?(:district)
		self.number ||= '' if self.has_attribute?(:number)
		self.complement ||= '' if self.has_attribute?(:complement)
		self.reference ||= '' if self.has_attribute?(:reference)
		self.address_area_id ||= AddressArea::GENERAL_ID if self.has_attribute?(:address_area_id)
	end

end
