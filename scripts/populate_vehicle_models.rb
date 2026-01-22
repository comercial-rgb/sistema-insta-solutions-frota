# Script para popular tabela vehicle_models com dados dos veículos existentes
# Execute: rails runner scripts/populate_vehicle_models.rb

puts "Populando tabela vehicle_models com dados existentes..."

# Buscar combinações únicas de marca/modelo dos veículos
vehicles_data = Vehicle.select(:brand, :model, :vehicle_type_id)
  .where.not(brand: [nil, ''])
  .where.not(model: [nil, ''])
  .distinct
  .pluck(:brand, :model, :vehicle_type_id)

puts "Encontrados #{vehicles_data.count} combinações únicas de marca/modelo"

created_count = 0
skipped_count = 0

vehicles_data.each do |brand, model, vehicle_type_id|
  # Normalizar textos
  brand_normalized = brand.to_s.strip.upcase
  model_normalized = model.to_s.strip.upcase
  
  next if brand_normalized.blank? || model_normalized.blank?
  
  # Verificar se já existe
  existing = VehicleModel.find_by(
    brand: brand_normalized,
    model: model_normalized
  )
  
  if existing
    skipped_count += 1
    next
  end
  
  # Criar novo registro
  vm = VehicleModel.new(
    brand: brand_normalized,
    model: model_normalized,
    vehicle_type_id: vehicle_type_id || 2, # Default: Automóvel
    full_name: "#{brand_normalized} #{model_normalized}",
    active: true
  )
  
  if vm.save
    created_count += 1
    print "." if created_count % 50 == 0
  else
    puts "\nErro ao criar #{brand_normalized} #{model_normalized}: #{vm.errors.full_messages.join(', ')}"
  end
end

puts "\n"
puts "="*60
puts "Importação concluída!"
puts "Criados: #{created_count}"
puts "Já existentes: #{skipped_count}"
puts "Total na tabela: #{VehicleModel.count}"
puts "="*60
