# Verifica encoding em services e order_service_proposal_items

puts "=" * 80
puts "VERIFICANDO ENCODING EM SERVIÇOS E ITENS DE PROPOSTAS"
puts "=" * 80

# Padrões a buscar
patterns = ['Ü', 'î', 'ÜÜ', 'nÜ']

puts "\n1. SERVICES (Peças e Serviços):"
puts "-" * 80

patterns.each do |pattern|
  count = Service.where('name LIKE ?', "%#{pattern}%").count
  puts "   Padrão '#{pattern}': #{count} registros"
end

puts "\n   Exemplos de nomes corrompidos:"
Service.where('name LIKE ? OR name LIKE ?', '%Ü%', '%î%')
  .limit(20)
  .each do |service|
    puts "   ID #{service.id}: #{service.name}"
  end

puts "\n2. ORDER_SERVICE_PROPOSAL_ITEMS (Itens em propostas):"
puts "-" * 80

patterns.each do |pattern|
  count = OrderServiceProposalItem.where('service_name LIKE ?', "%#{pattern}%").count
  puts "   Padrão '#{pattern}': #{count} registros"
end

puts "\n   Exemplos de nomes corrompidos em itens:"
OrderServiceProposalItem.where('service_name LIKE ? OR service_name LIKE ?', '%Ü%', '%î%')
  .limit(20)
  .each do |item|
    puts "   ID #{item.id}: #{item.service_name}"
  end

puts "\n3. PROVIDER_SERVICE_TEMPS (Itens temporários):"
puts "-" * 80

begin
  patterns.each do |pattern|
    count = ProviderServiceTemp.where('service_name LIKE ?', "%#{pattern}%").count
    puts "   Padrão '#{pattern}': #{count} registros"
  end
  
  puts "\n   Exemplos:"
  ProviderServiceTemp.where('service_name LIKE ? OR service_name LIKE ?', '%Ü%', '%î%')
    .limit(10)
    .each do |item|
      puts "   ID #{item.id}: #{item.service_name}"
    end
rescue => e
  puts "   (Erro ao verificar: #{e.message})"
end

puts "\n" + "=" * 80
puts "VERIFICAÇÃO CONCLUÍDA"
puts "=" * 80
