os = OrderService.find_by(code: 'OS6805722026112')

if os.nil?
  puts "OS não encontrada!"
  exit
end

puts "=== OS6805722026112 ==="
puts "ID: #{os.id}"
puts "Status da OS: #{os.order_service_status&.name} (ID: #{os.order_service_status_id})"
puts "Cliente: #{os.client&.fantasy_name || os.client&.name}"
puts "\nPropostas:"

os.order_service_proposals.each do |p|
  puts "\n  Proposta ##{p.id}:"
  puts "    Status: #{p.order_service_proposal_status&.name} (ID: #{p.order_service_proposal_status_id})"
  puts "    Fornecedor: #{p.provider&.fantasy_name || p.provider&.name}"
  puts "    Valor total: R$ #{p.total_value}"
  puts "    Aprovada por: #{p.approved_by_additional&.name || 'N/A'}"
  puts "    Data aprovação: #{p.approved_by_additional_at || 'N/A'}"
end

# Verificar se há proposta aprovada
proposta_aprovada = os.order_service_proposals.find_by(order_service_proposal_status_id: 3)

if proposta_aprovada
  puts "\n⚠️ INCONSISTÊNCIA DETECTADA!"
  puts "A OS tem proposta APROVADA mas o status da OS é '#{os.order_service_status&.name}'"
  puts "\n=== CORRIGINDO ==="
  
  old_status = os.order_service_status_id
  new_status = 3 # APROVADA_ID
  
  # Atualizar status da OS
  OrderService.where(id: os.id).update_all(order_service_status_id: new_status)
  
  # Gerar histórico
  admin_user = User.find_by(email: 'admin@sistema.com') || User.where(profile_id: 1).first
  if admin_user
    OrderService.generate_historic(os, admin_user, old_status, new_status)
  end
  
  puts "✓ Status da OS atualizado: #{old_status} → #{new_status}"
  puts "✓ Histórico gerado"
  
  # Verificar resultado
  os.reload
  puts "\n=== STATUS ATUALIZADO ==="
  puts "Status atual da OS: #{os.order_service_status&.name} (ID: #{os.order_service_status_id})"
else
  puts "\n✓ Nenhuma proposta aprovada encontrada. Status da OS está correto."
end
