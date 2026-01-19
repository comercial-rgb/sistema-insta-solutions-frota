class PersonType < ApplicationRecord
	validates_presence_of :name

	def as_json(options = {})
		{
			:id => self.id,
			:name => self.name
		}
	end

	FISICA = 'Física'
	JURIDICA = 'Jurídica'

	FISICA_ID = 1
	JURIDICA_ID = 2

end
