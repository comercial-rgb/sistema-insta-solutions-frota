class StateSerializer < ActiveModel::Serializer

	attributes :id,
	:acronym,
	:name,
	:ibge_code

	belongs_to :country

end  