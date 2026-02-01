# Analisar OSs que têm proposta aprovada mas a OS está com status errado
puts '=== OSs COM PROPOSTA APROVADA MAS STATUS DA OS INCORRETO ==='

# Buscar OSs que têm pelo menos uma proposta com status APROVADA (14)
# mas a própria OS não está com status APROVADA (5)
os_with_approved_proposals = OrderService.joins(:order_service_proposals)
  .where(order_service_proposals: { order_service_proposal_status_id: 14 })
  .where.not(order_service_status_id: 5)
  .distinct

puts "Total: #{os_with_approved_proposals.count}"
os_with_approved_proposals.limit(20).each do |os|
  approved_count = os.order_service_proposals.where(order_service_proposal_status_id: 14).count
  puts "\n  OS #{os.code} (ID: #{os.id})"
  puts "    Status da OS: #{os.order_service_status&.name} (ID: #{os.order_service_status_id})"
  puts "    Propostas aprovadas: #{approved_count}"
  os.order_service_proposals.where(order_service_proposal_status_id: 14).each do |p|
    puts "      - Proposta ##{p.id} APROVADA"
  end
end

# Analisar OSs em "Aguardando avaliação" que têm propostas mas nenhuma em avaliação
puts "\n\n=== OSs EM 'AGUARDANDO AVALIAÇÃO' MAS SEM PROPOSTAS AGUARDANDO ==="
os_waiting_without_proposals = OrderService.left_joins(:order_service_proposals)
  .where(order_service_status_id: 4) # AGUARDANDO_AVALIACAO_PROPOSTA_ID
  .group('order_services.id')
  .having('SUM(CASE WHEN order_service_proposals.order_service_proposal_status_id = 13 THEN 1 ELSE 0 END) = 0')

puts "Total: #{os_waiting_without_proposals.count}"
os_waiting_without_proposals.limit(20).each do |os|
  proposal_count = os.order_service_proposals.count
  puts "\n  OS #{os.code} (ID: #{os.id})"
  puts "    Status da OS: #{os.order_service_status&.name} (ID: #{os.order_service_status_id})"
  puts "    Total de propostas: #{proposal_count}"
  if proposal_count > 0
    os.order_service_proposals.each do |p|
      puts "      - Proposta ##{p.id}: #{p.order_service_proposal_status&.name} (ID: #{p.order_service_proposal_status_id})"
    end
  end
end

# Análise geral de inconsistências
puts "\n\n=== RESUMO DE INCONSISTÊNCIAS ==="
total_os = OrderService.count
total_approved_proposals = OrderServiceProposal.where(order_service_proposal_status_id: 14).count
total_os_aguardando = OrderService.where(order_service_status_id: 4).count

puts "Total de OSs no sistema: #{total_os}"
puts "Total de propostas aprovadas: #{total_approved_proposals}"
puts "Total de OSs em 'Aguardando avaliação': #{total_os_aguardando}"

# Verificar se há callbacks ou validações que deveriam atualizar o status
puts "\n\n=== TESTE: Atualizar status das OSs inconsistentes ==="
os_with_approved_proposals.limit(5).each do |os|
  puts "\nOS #{os.code}:"
  puts "  Status atual: #{os.order_service_status_id}"
  puts "  Deveria ser: 5 (APROVADA)"
  # Não vamos atualizar ainda, só reportar
end
