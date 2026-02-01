# Verificar registros ainda com encoding errado
conn = ActiveRecord::Base.connection

puts "=" * 60
puts "VERIFICANDO REGISTROS COM ENCODING ERRADO"
puts "=" * 60

# Verificar person_types
puts "\nPERSON_TYPES:"
PersonType.all.each { |p| puts "  ID #{p.id}: #{p.name}" }

# Verificar provider_service_types
puts "\nPROVIDER_SERVICE_TYPES (amostra):"
ProviderServiceType.limit(10).each { |p| puts "  ID #{p.id}: #{p.name}" }

# Verificar banks
puts "\nBANKS (amostra):"
Bank.limit(10).each { |b| puts "  ID #{b.id}: #{b.name}" }

# Verificar cidades
puts "\nCITIES (amostra):"
City.limit(10).each { |c| puts "  ID #{c.id}: #{c.name}" }

# Verificar endereços com caracteres problemáticos
puts "\nENDEREÇOS - Buscando registros com ? ou ç errado:"
Address.where("district LIKE '%?%' OR address LIKE '%?%'").each do |a|
  puts "  ID #{a.id}: bairro='#{a.district}' rua='#{a.address}'"
end

puts "\n" + "=" * 60
puts "VERIFICAÇÃO CONCLUÍDA"
puts "=" * 60
