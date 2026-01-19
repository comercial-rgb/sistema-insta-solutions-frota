class Bank < ApplicationRecord

	default_scope {order(number: :asc)}

	def get_formatted_name
		return self.number + ' / '+self.name
	end

	def as_json(options = {})
		{
			:id => self.id,
			:name => self.name,
			formatted_name: self.get_formatted_name
		}
	end

end
