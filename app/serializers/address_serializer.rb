class AddressSerializer < ActiveModel::Serializer

	attributes :id

	attribute :name do
		if !object.nil?
			object.name
		end
	end

	attribute :complete_address do
		object.get_address_value
	end

	attribute :address do
		if !object.nil?
			object.address
		end
	end

	attribute :number do
		if !object.nil?
			object.number
		end
	end

	attribute :complement do
		if !object.nil?
			object.complement
		end
	end

	attribute :district do
		if !object.nil?
			object.district
		end
	end

	attribute :city_id do
		if !object.nil?
			object.city_id
		end
	end

	attribute :city_name do
		if !object.nil? && !object.city.nil?
			object.city.name
		end
	end

	attribute :state_id do
		if !object.nil?
			object.state_id
		end
	end

	attribute :state_name do
		if !object.nil? && !object.state.nil?
			object.state.name
		end
	end

	attribute :zipcode do
		if !object.nil?
			object.zipcode
		end
	end

	attribute :reference do
		if !object.nil?
			object.reference
		end
	end

	attribute :address_type_id do
		if !object.nil?
			object.address_type_id
		end
	end

	attribute :address_type_name do
		if !object.nil? && !object.address_type.nil?
			object.address_type.name
		end
	end

end  