# Busca registros com caracteres ???? no banco
puts "Buscando registros com encoding incorreto..."
puts "=" * 60

# Verificar order_service_types
puts "\n1. ORDER_SERVICE_TYPES:"
OrderServiceType.all.each do |t|
  if t.name.include?("?")
    puts "  ID #{t.id}: #{t.name}"
  end
end

# Verificar services
puts "\n2. SERVICES (primeiros 20 com ????):"
services_with_issue = Service.where("name LIKE ?", "%?%").limit(20)
puts "  Total encontrados: #{Service.where("name LIKE ?", "%?%").count}"
services_with_issue.each do |s|
  puts "  ID #{s.id}: #{s.name}"
end

# Verificar vehicles (marca/modelo)
puts "\n3. VEHICLES (marcas com ????):"
vehicles_brands = Vehicle.where("brand LIKE ?", "%?%").select(:brand).distinct.limit(10)
vehicles_brands.each do |v|
  puts "  Marca: #{v.brand}"
end

# Verificar users
puts "\n4. USERS (nomes com ????):"
users_with_issue = User.where("name LIKE ?", "%?%").limit(10)
puts "  Total encontrados: #{User.where("name LIKE ?", "%?%").count}"
users_with_issue.each do |u|
  puts "  ID #{u.id}: #{u.name}"
end

puts "\n" + "=" * 60
puts "Busca concluída!"
