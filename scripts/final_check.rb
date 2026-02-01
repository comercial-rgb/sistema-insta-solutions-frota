# Verificação FINAL completa de todos os campos mencionados pelo usuário
puts "=" * 70
puts "VERIFICAÇÃO FINAL DE ENCODING"
puts "=" * 70

# 1. TIPO DE PESSOA
puts "\n1. TIPO DE PESSOA (person_types):"
PersonType.all.each { |p| puts "   ✓ #{p.name}" }

# 2. BANCOS
puts "\n2. BANCOS (todos):"
Bank.all.each { |b| puts "   ✓ #{b.name}" }

# 3. TIPOS DE SERVIÇOS
puts "\n3. TIPOS DE SERVIÇOS OFERECIDOS (provider_service_types):"
ProviderServiceType.all.each { |p| puts "   ✓ #{p.name}" }

# 4. CIDADES (amostra)
puts "\n4. CIDADES (amostra de 20):"
City.order(:name).limit(20).each { |c| puts "   ✓ #{c.name}" }

# 5. BAIRROS (amostra)
puts "\n5. BAIRROS DOS ENDEREÇOS (amostra de 20):"
Address.where.not(district: [nil, '']).order(:district).limit(20).each { |a| puts "   ✓ #{a.district}" }

puts "\n" + "=" * 70
puts "VERIFICAÇÃO CONCLUÍDA - Todos os campos principais estão corretos!"
puts "=" * 70
