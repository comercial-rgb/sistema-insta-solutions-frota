os1 = OrderService.find_by(code: 'OS42565202619')
puts '=== OS42565202619 ==='
if os1
  puts "ID: #{os1.id}"
  puts "Status: #{os1.order_service_status&.name} (ID: #{os1.order_service_status_id})"
  puts "Propostas: #{os1.order_service_proposals.count}"
  os1.order_service_proposals.each do |p|
    puts "  - Proposta ##{p.id}: #{p.order_service_proposal_status&.name} (ID: #{p.order_service_proposal_status_id})"
  end
else
  puts 'OS não encontrada'
end

os2 = OrderService.find_by(code: 'OS4234820251118')
puts ''
puts '=== OS4234820251118 ==='
if os2
  puts "ID: #{os2.id}"
  puts "Status: #{os2.order_service_status&.name} (ID: #{os2.order_service_status_id})"
  puts "Propostas: #{os2.order_service_proposals.count}"
  os2.order_service_proposals.each do |p|
    puts "  - Proposta ##{p.id}: #{p.order_service_proposal_status&.name} (ID: #{p.order_service_proposal_status_id})"
  end
else
  puts 'OS não encontrada'
end

# Verificar OSs com propostas aprovadas mas status diferente de APROVADA_ID
puts ''
puts '=== ANÁLISE DE INCONSISTÊNCIAS ==='
inconsistent_os = OrderService.joins(:order_service_proposals)
  .where(order_service_proposals: { order_service_proposal_status_id: 14 })
  .where.not(order_service_status_id: 9)
  .distinct

puts "OSs com proposta aprovada mas status != APROVADA (9): #{inconsistent_os.count}"
inconsistent_os.limit(10).each do |os|
  puts "  - OS #{os.code}: Status atual = #{os.order_service_status_id} (#{os.order_service_status&.name})"
end

# Verificar OSs em "Aguardando avaliação" sem propostas
puts ''
os_without_proposals = OrderService.left_joins(:order_service_proposals)
  .where(order_service_status_id: 4)
  .group('order_services.id')
  .having('COUNT(order_service_proposals.id) = 0')

puts "OSs em 'Aguardando avaliação' SEM propostas: #{os_without_proposals.count}"
os_without_proposals.limit(10).each do |os|
  puts "  - OS #{os.code}: #{os.order_service_status&.name}"
end
