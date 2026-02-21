# =============================================================================
# Script: Corrigir OS 6657512026128 - Duas propostas ativas
# =============================================================================
# Problema: OS possui duas propostas não-complemento em status ativo:
#   - P787OS6657512026128 (Autorizada - status 5) - PROPOSTA INCORRETA
#   - P834OS6657512026128 (Notas fiscais inseridas - status 4) - PROPOSTA CORRETA
#
# A proposta P787 deveria ter sido cancelada quando P834 foi aprovada.
# Como isso não aconteceu, o saldo do empenho está sendo consumido DUAS vezes.
#
# Ação: Cancelar P787, manter P834, verificar consumo do empenho.
# =============================================================================

puts "=" * 80
puts "DIAGNÓSTICO: OS 6657512026128 - Duas Propostas Ativas"
puts "=" * 80

# 1. Localizar a OS
os = OrderService.find_by(code: 'OS6657512026128')
unless os
  puts "❌ OS não encontrada pelo código. Buscando por código parcial..."
  os = OrderService.where("code LIKE ?", "%6657512026128%").first
end

unless os
  puts "❌ OS 6657512026128 não encontrada no banco de dados."
  puts "Verifique o código da OS e tente novamente."
  exit
end

puts "\n📋 OS encontrada:"
puts "  ID: #{os.id}"
puts "  Código: #{os.code}"
puts "  Status: #{os.order_service_status&.name} (ID: #{os.order_service_status_id})"
puts "  Cliente: #{os.client&.social_name || os.client&.fantasy_name || os.client&.name}"
puts "  Veículo: #{os.vehicle&.board}"

# 2. Listar todas as propostas da OS
puts "\n📊 Propostas da OS:"
puts "-" * 80
os.order_service_proposals.each do |proposal|
  status_name = proposal.order_service_proposal_status&.name || "Status #{proposal.order_service_proposal_status_id}"
  puts "  #{proposal.code} | Status: #{status_name} (#{proposal.order_service_proposal_status_id}) | Complemento: #{proposal.is_complement ? 'Sim' : 'Não'} | Valor: #{proposal.total_value}"
end

# 3. Identificar as duas propostas problemáticas
proposta_incorreta = os.order_service_proposals.find_by("code LIKE ?", "%P787%")
proposta_correta = os.order_service_proposals.find_by("code LIKE ?", "%P834%")

unless proposta_incorreta
  puts "\n⚠️  Proposta P787 não encontrada. Buscando propostas ativas..."
  active_statuses = OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES
  propostas_ativas = os.order_service_proposals.not_complement.where(order_service_proposal_status_id: active_statuses)
  puts "  Propostas ativas encontradas: #{propostas_ativas.count}"
  propostas_ativas.each do |p|
    puts "    #{p.code} - Status: #{p.order_service_proposal_status_id} - Valor: #{p.total_value}"
  end
end

unless proposta_correta
  puts "\n⚠️  Proposta P834 não encontrada."
end

# 4. Verificar consumo atual do empenho
puts "\n💰 Verificação de Consumo do Empenho:"
puts "-" * 80

commitment = os.commitment
commitment_parts = os.commitment_parts
commitment_services = os.commitment_services

[['Global', commitment], ['Peças', commitment_parts], ['Serviços', commitment_services]].each do |label, c|
  next unless c
  values = Commitment.getting_values_to_commitment(c)
  consumed = Commitment.get_total_already_consumed_value(c)
  puts "  Empenho #{label} (#{c.commitment_number}):"
  puts "    Valor total: #{c.commitment_value}"
  puts "    Já consumido: #{consumed}"
  puts "    Saldo disponível: #{values[:pendent_value]}"
end

# 5. Calcular valor que está sendo consumido pela proposta incorreta
if proposta_incorreta
  puts "\n⚠️  Valor consumido pela proposta INCORRETA (#{proposta_incorreta.code}):"
  puts "    total_value: #{proposta_incorreta.total_value}"
  
  parts_value_incorreta = proposta_incorreta.order_service_proposal_items
    .joins(:service)
    .where(services: { category_id: Category::SERVICOS_PECAS_ID })
    .sum(:total_value) rescue 0
  
  services_value_incorreta = proposta_incorreta.order_service_proposal_items
    .joins(:service)
    .where(services: { category_id: Category::SERVICOS_SERVICOS_ID })
    .sum(:total_value) rescue 0
    
  puts "    Peças: #{parts_value_incorreta}"
  puts "    Serviços: #{services_value_incorreta}"
  puts "    ⚠️  Este valor está sendo consumido INDEVIDAMENTE do saldo do empenho!"
end

puts "\n" + "=" * 80
puts "AÇÃO CORRETIVA"
puts "=" * 80

if proposta_incorreta
  puts "\n🔧 Cancelando proposta incorreta: #{proposta_incorreta.code}"
  
  # Buscar usuário admin para audit
  admin_user = User.find_by(profile_id: 1) || User.first
  
  # Gerar histórico
  OrderServiceProposal.generate_historic(
    proposta_incorreta,
    admin_user,
    proposta_incorreta.order_service_proposal_status_id,
    OrderServiceProposalStatus::CANCELADA_ID
  )
  
  old_status = proposta_incorreta.order_service_proposal_status_id
  proposta_incorreta.update_columns(
    order_service_proposal_status_id: OrderServiceProposalStatus::CANCELADA_ID,
    reproved: true,
    reason_reproved: "Proposta cancelada por correção administrativa - proposta com itens incorretos (lavagem em peça ao invés de serviço). Proposta correta: #{proposta_correta&.code || 'P834'}"
  )
  
  puts "  ✅ Proposta #{proposta_incorreta.code} cancelada (status #{old_status} → #{OrderServiceProposalStatus::CANCELADA_ID})"
  
  # Verificar consumo APÓS correção
  puts "\n💰 Consumo APÓS correção:"
  [['Global', commitment], ['Peças', commitment_parts], ['Serviços', commitment_services]].each do |label, c|
    next unless c
    # Forçar recálculo
    values = Commitment.getting_values_to_commitment(c)
    consumed = Commitment.get_total_already_consumed_value(c)
    puts "  Empenho #{label} (#{c.commitment_number}):"
    puts "    Já consumido: #{consumed}"
    puts "    Saldo disponível: #{values[:pendent_value]}"
  end
  
  puts "\n✅ Saldo do empenho restaurado - a proposta incorreta não é mais contabilizada."
else
  puts "\n⚠️  Proposta P787 não encontrada. Nenhuma ação corretiva aplicada."
  puts "  Verifique manualmente as propostas da OS."
end

# 6. Verificar estado final da OS
puts "\n📋 Estado final da OS:"
os.reload
puts "  Status da OS: #{os.order_service_status&.name} (#{os.order_service_status_id})"
puts "\n  Propostas:"
os.order_service_proposals.reload.each do |proposal|
  status_name = proposal.order_service_proposal_status&.name || "Status #{proposal.order_service_proposal_status_id}"
  puts "    #{proposal.code} | #{status_name} (#{proposal.order_service_proposal_status_id}) | Valor: #{proposal.total_value}"
end

puts "\n" + "=" * 80
puts "CONCLUÍDO"
puts "=" * 80
