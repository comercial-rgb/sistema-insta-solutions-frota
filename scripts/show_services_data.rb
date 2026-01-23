# Ver dados reais da tabela services

puts "=" * 60
puts "DADOS DA TABELA SERVICES (primeiros 15)"
puts "=" * 60

Service.limit(15).each do |service|
  category_name = service.category.name rescue 'N/A'
  puts "\nID #{service.id}:"
  puts "  Categoria: #{category_name}"
  puts "  Nome: #{service.name}"
  puts "  Bytes: #{service.name.bytes.join(',')}"
end
