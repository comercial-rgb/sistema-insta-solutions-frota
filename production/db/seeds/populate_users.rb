admin = Profile.find_or_create_by(name: Profile::ADMIN)
user = Profile.find_or_create_by(name: Profile::USER)
client = Profile.find_or_create_by(name: Profile::CLIENT)
manager = Profile.find_or_create_by(name: Profile::MANAGER)
additional = Profile.find_or_create_by(name: Profile::ADDITIONAL)
provider = Profile.find_or_create_by(name: Profile::PROVIDER)

User.create(person_type_id: 1,
	sex_id: rand(1..2),
	user_status_id: UserStatus::APROVADO_ID,
	name: 'Administrador Geral',
	profile: admin,
	email: ENV['ADMIN_1'],
	access_user: ENV['ADMIN_1_ACCESS_USER'],
	password: ENV['ADMIN_1_SENHA'],
	seed: true,
	cpf: "311.191.150-00",
	phone: "(99) 99999-9999",
	cellphone: "(99) 99999-9999",
	new_user: true)

User.create(person_type_id: 1,
	sex_id: rand(1..2),
	user_status_id: UserStatus::APROVADO_ID,
	name: 'Administrador Geral',
	profile: admin,
	email: ENV['ADMIN_2'],
	access_user: ENV['ADMIN_2_ACCESS_USER'],
	password: ENV['ADMIN_2_SENHA'],
	seed: true,
	cpf: "487.643.960-53",
	phone: "(99) 99999-9999",
	cellphone: "(99) 99999-9999",
	new_user: true)
