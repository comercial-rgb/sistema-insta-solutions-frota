class UserSerializer < ActiveModel::Serializer

	attributes :id,
	:created_at,
	:updated_at,
	:name,
	:email,
	:access_user,
	:is_blocked,
	:profile_id,
	:profile,
	:phone,
	:cpf,
	:rg,
	:birthday,
	:person_type_id,
	:person_type,
	:sex_id,
	:sex,
	:payment_type_id,
	:payment_type,
	:civil_state_id,
	:civil_state,
	:social_name,
	:fantasy_name,
	:cnpj,
	:accept_therm,
	:cellphone,
	:profession,
	:provider,
	:uid

	attribute :profile_image_url do
		CustomHelper.url_for(object.profile_image)
	end
	
	has_one :attachment
	has_one :address
	has_many :phones
	has_many :emails
	has_many :data_banks
	has_many :cards
	has_many :addresses

	attribute :created_at_formatted do
		CustomHelper.get_text_date(object.created_at, 'datetime', :full)
	end

	attribute :updated_at_formatted do
		CustomHelper.get_text_date(object.updated_at, 'datetime', :full)
	end

	attribute :birthday_formatted do
		CustomHelper.get_text_date(object.birthday, 'date', :default)
	end
end  