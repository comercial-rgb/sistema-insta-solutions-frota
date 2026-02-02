#!/usr/bin/env ruby
# Script para encontrar outras OSs com múltiplas propostas ativas

require_relative 'production/config/environment'

puts "=" * 80
puts "AUDITORIA: OSs com Múltiplas Propostas Ativas"
puts "=" * 80

# Buscar OSs com múltiplas propostas em status "ativos"
active_statuses = OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES

puts "\nBuscando OSs com múltiplas propostas em status:"
active_statuses.each do |status_id|
  status = OrderServiceProposalStatus.find_by(id: status_id)
  puts "  - #{status&.name} (ID: #{status_id})"
end

puts "\n" + "-" * 80
puts "Consultando banco de dados..."
puts "-" * 80

# Query para encontrar OSs problemáticas
problematic_os = OrderService
  .unscoped
  .joins(:order_service_proposals)
  .where('order_service_proposals.order_service_proposal_status_id IN (?)', active_statuses)
  .where('order_service_proposals.is_complement IS NULL OR order_service_proposals.is_complement = ?', false)
  .group('order_services.id', 'order_services.code')
  .having('COUNT(DISTINCT order_service_proposals.id) > 1')
  .select('order_services.id', 'order_services.code', 'COUNT(DISTINCT order_service_proposals.id) as proposal_count')

total_found = problematic_os.count

puts "\n📊 RESULTADO: #{total_found} OSs encontradas com múltiplas propostas ativas\n"

if total_found == 0
  puts "✅ Nenhuma OS com múltiplas propostas ativas encontrada!"
  puts "   O problema da OS6657512026128 parece ser um caso isolado."
else
  puts "⚠️  Foram encontradas #{total_found} OSs com o mesmo problema!\n"
  puts "=" * 80
  
  problematic_os.each_with_index do |os_data, index|
    os = OrderService.unscoped.find(os_data.id)
    
    puts "\n#{index + 1}. OS: #{os.code} (ID: #{os.id})"
    puts "   Cliente: #{os.client&.fantasy_name}"
    puts "   Status OS: #{os.order_service_status&.name}"
    puts "   Propostas Ativas: #{os_data.proposal_count}"
    
    # Listar as propostas ativas
    active_proposals = os.order_service_proposals
      .unscoped
      .where(order_service_proposal_status_id: active_statuses)
      .where('is_complement IS NULL OR is_complement = ?', false)
      .order(:created_at)
    
    active_proposals.each do |prop|
      puts "     - #{prop.code} | Status: #{prop.order_service_proposal_status&.name} | Valor: R$ #{prop.total_value} | Criada: #{prop.created_at.strftime('%d/%m/%Y %H:%M')}"
    end
    
    puts "   " + "-" * 76
  end
  
  puts "\n" + "=" * 80
  puts "ESTATÍSTICAS"
  puts "=" * 80
  
  # Contar por tipo de combinação de status
  status_combinations = {}
  
  problematic_os.each do |os_data|
    os = OrderService.unscoped.find(os_data.id)
    proposals = os.order_service_proposals
      .unscoped
      .where(order_service_proposal_status_id: active_statuses)
      .where('is_complement IS NULL OR is_complement = ?', false)
    
    statuses = proposals.map { |p| p.order_service_proposal_status&.name }.sort
    combination = statuses.join(' + ')
    
    status_combinations[combination] ||= 0
    status_combinations[combination] += 1
  end
  
  puts "\nCombinações de Status Encontradas:"
  status_combinations.sort_by { |k, v| -v }.each do |combination, count|
    puts "  #{count}x - #{combination}"
  end
end

puts "\n" + "=" * 80
puts "RECOMENDAÇÕES"
puts "=" * 80

if total_found > 0
  puts "\n1. URGENTE: Revisar cada OS manualmente"
  puts "2. Verificar consumo duplo de saldo em cada caso"
  puts "3. Cancelar propostas indevidas"
  puts "4. Implementar validações no código (ver ANALISE_OS6657512026128_DUAS_PROPOSTAS.md)"
  puts "5. Monitorar recorrência do problema após implementar validações"
else
  puts "\n1. Implementar validações preventivas (ver ANALISE_OS6657512026128_DUAS_PROPOSTAS.md)"
  puts "2. Monitorar criação de novas propostas"
  puts "3. Revisar processo de cancelamento e reenvio de propostas"
end

puts "\n" + "=" * 80
puts "FIM DA AUDITORIA"
puts "=" * 80
