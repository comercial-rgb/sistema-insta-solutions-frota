class Sex < ApplicationRecord
	
	MASCULINO_ID = 1
	FEMININO_ID = 2
	NAO_QUERO_INFORMAR_ID = 3
	
	def as_json(options = {})
		{
			:id => self.id,
			:name => self.name
		}
	end
	
end
