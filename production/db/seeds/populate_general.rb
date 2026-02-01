# # Models
# register_numbers = 3
# models = []
# FactoryBot.factories.instance_variable_get('@items').map { |name| models << name[0] }
# models -= [:country, 
# 	:state, 
# 	:city, 
# 	:address, 
# 	:phone_type, 
# 	:phone, 
# 	:email_type, 
# 	:email, 
# 	:attachment,
# 	:data_bank,
# 	:card_banner,
# 	:card,
# 	:profile,
# 	:person_type, 
# 	:user,
# 	:api_key,
# 	:system_configuration,
# 	:payment_status,
# 	:product,
# 	:order,
# 	:civil_state,
# ]
# # Extract Migrations
# migrations = Dir['db/migrate/[0-9]*.rb'].sort_by { |f| File.basename(f).to_i }
# migrations = migrations.map {|item| item.slice(33..-4).to_sym}
# migrations.drop(1)
# # Define orderxs
# models.sort_by { |x| migrations.index x.to_s }
# # Populate Database
# models.map { |model| register_numbers.times.collect { FactoryBot.create(model) } }