#!/usr/bin/env ruby
# Script para corrigir status de OS que tem proposta aprovada mas não foi atualizada

# Encontrar todas as OSs com propostas aprovadas mas que estão com status incorreto
puts "=== Buscando OSs com status incorreto ==="
puts ""

# OSs que tem proposta aprovada (status 3) mas a OS não está com status 5 (Aprovada)
problematic_os = OrderService
  .joins(:order_service_proposals)
  .where(order_service_proposals: { order_service_proposal_status_id: OrderServiceProposalStatus::APROVADA_ID })
  .where.not(order_service_status_id: OrderServiceStatus::APROVADA_ID)
  .distinct

puts "Encontradas #{problematic_os.count} OSs com propostas aprovadas mas status incorreto:"
puts ""

problematic_os.each do |os|
  approved_proposal = os.order_service_proposals.find_by(order_service_proposal_status_id: OrderServiceProposalStatus::APROVADA_ID)
  
  puts "OS: #{os.code}"
  puts "  Status atual: #{os.order_service_status_id} - #{os.order_service_status.name}"
  puts "  Proposta aprovada: #{approved_proposal.code} (ID: #{approved_proposal.id})"
  puts "  Data de aprovação: #{approved_proposal.updated_at}"
  puts ""
end

# Corrigir especificamente a OS6805722026112
puts "=== Corrigindo OS6805722026112 ==="
os_to_fix = OrderService.find_by(code: 'OS6805722026112')

if os_to_fix
  old_status = os_to_fix.order_service_status_id
  old_status_name = os_to_fix.order_service_status.name
  
  # Atualizar status da OS
  OrderService.where(id: os_to_fix.id).update_all(order_service_status_id: OrderServiceStatus::APROVADA_ID)
  
  # Recarregar do banco
  os_to_fix.reload
  
  puts "OS: #{os_to_fix.code}"
  puts "  Status anterior: #{old_status} - #{old_status_name}"
  puts "  Status novo: #{os_to_fix.order_service_status_id} - #{os_to_fix.order_service_status.name}"
  puts "  ✅ Atualizado com sucesso!"
else
  puts "❌ OS6805722026112 não encontrada"
end

puts ""
puts "=== Script finalizado ==="
