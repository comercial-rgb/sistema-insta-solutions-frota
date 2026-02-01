client = Profile.find_or_create_by(name: Profile::CLIENT)
provider = Profile.find_or_create_by(name: Profile::PROVIDER)
manager = Profile.find_or_create_by(name: Profile::MANAGER)
additional = Profile.find_or_create_by(name: Profile::ADDITIONAL)

if ENV['DOMAIN_NAME'].include?('teste')
	FactoryBot.create_list(:provider_service_type, 6)
	FactoryBot.create_list(:vehicle_type, 6)
	FactoryBot.create_list(:category, 6, category_type_id: CategoryType::VEICULOS_ID)
	for i in 0..4
		FactoryBot.create(:user, profile_id: client.id)
		FactoryBot.create(:user, profile_id: provider.id)
		FactoryBot.create(:user, profile_id: manager.id)
		FactoryBot.create(:user, profile_id: additional.id)
	end
	FactoryBot.create_list(:contract, 10)
	for i in 0..4
		FactoryBot.create(:cost_center)
		FactoryBot.create(:vehicle)
	end
	FactoryBot.create_list(:service, 30)
	FactoryBot.create_list(:order_service, 30)
	
	# Criar grupos de serviço de exemplo
	ServiceGroup.find_or_create_by(name: 'Conserto de pneu') do |sg|
		sg.value_limit = 500.00
		sg.active = true
	end
	
	ServiceGroup.find_or_create_by(name: 'Lavagem Automotiva') do |sg|
		sg.value_limit = 300.00
		sg.active = true
	end
	
	ServiceGroup.find_or_create_by(name: 'Troca de óleo') do |sg|
		sg.value_limit = 400.00
		sg.active = true
	end
	
	ServiceGroup.find_or_create_by(name: 'Alinhamento e Balanceamento') do |sg|
		sg.value_limit = 350.00
		sg.active = true
	end
end
