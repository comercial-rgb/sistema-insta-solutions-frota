class CitySerializer < ActiveModel::Serializer

	attributes :id,
	:name,
	:latitude,
	:longitude,
	:state_id,
	:ibge_code,
	:quantity_population

end  