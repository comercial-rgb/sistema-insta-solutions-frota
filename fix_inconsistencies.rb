# Script para corrigir inconsistências de status no banco
puts '=== CORREÇÃO DE INCONSISTÊNCIAS DE STATUS ==='

# 1. Corrigir OSs que estão com status incorreto baseado no status das propostas
puts "\n1. Corrigindo OSs com status inconsistente baseado nas propostas..."

# OSs com status 4 (AGUARDANDO_AVALIACAO_PROPOSTA) mas que têm propostas com status 4 (antigo "Notas inseridas", que é 15 no novo)
# Devem ser corrigidas para status 6 (NOTA_FISCAL_INSERIDA)
os_para_corrigir_nf = OrderService.joins(:order_service_proposals)
  .where(order_service_status_id: 4) # Status da OS: Aguardando avaliação
  .where(order_service_proposals: { order_service_proposal_status_id: [4, 5, 6, 7] }) # Propostas com IDs antigos (NF inserida, autorizada, etc)
  .distinct

puts "OSs a corrigir (propostas já têm NF): #{os_para_corrigir_nf.count}"

os_para_corrigir_nf.each do |os|
  proposta = os.order_service_proposals.first
  old_status = os.order_service_status_id
  
  # Mapear status antigo da proposta para novo status da OS
  new_os_status = case proposta.order_service_proposal_status_id
  when 4 then 6  # Notas inseridas antigo → NOTA_FISCAL_INSERIDA
  when 5 then 7  # Autorizada antigo → AUTORIZADA
  when 6 then 8  # Aguardando pagamento antigo → AGUARDANDO_PAGAMENTO
  when 7 then 9  # Paga antigo → PAGA
  else os.order_service_status_id
  end
  
  if old_status != new_os_status
    puts "  Corrigindo OS #{os.code}: #{old_status} → #{new_os_status}"
    OrderService.where(id: os.id).update_all(order_service_status_id: new_os_status)
    # Criar histórico da correção
    OrderService.generate_historic(os, User.find_by(email: 'admin@sistema.com') || User.first, old_status, new_os_status)
  end
end

# 2. Corrigir OSs com status 2 (EM_ABERTO) que têm propostas com status antigo
os_em_aberto_com_propostas_antigas = OrderService.joins(:order_service_proposals)
  .where(order_service_status_id: 2) # EM_ABERTO
  .where(order_service_proposals: { order_service_proposal_status_id: [3, 4, 5, 6, 7] }) # Propostas aprovadas ou mais avançadas (IDs antigos)
  .distinct

puts "\nOSs em 'EM_ABERTO' mas com propostas aprovadas/avançadas: #{os_em_aberto_com_propostas_antigas.count}"

os_em_aberto_com_propostas_antigas.each do |os|
  proposta = os.order_service_proposals
                .where(order_service_proposal_status_id: [3, 4, 5, 6, 7])
                .order(order_service_proposal_status_id: :desc)
                .first
  
  old_status = os.order_service_status_id
  
  new_os_status = case proposta.order_service_proposal_status_id
  when 3 then 5  # Aprovada antigo → APROVADA
  when 4 then 6  # Notas inseridas antigo → NOTA_FISCAL_INSERIDA
  when 5 then 7  # Autorizada antigo → AUTORIZADA
  when 6 then 8  # Aguardando pagamento antigo → AGUARDANDO_PAGAMENTO
  when 7 then 9  # Paga antigo → PAGA
  else os.order_service_status_id
  end
  
  if old_status != new_os_status
    puts "  Corrigindo OS #{os.code}: #{old_status} → #{new_os_status}"
    OrderService.where(id: os.id).update_all(order_service_status_id: new_os_status)
    OrderService.generate_historic(os, User.find_by(email: 'admin@sistema.com') || User.first, old_status, new_os_status)
  end
end

puts "\n=== RESUMO DA CORREÇÃO ==="
puts "Correção concluída!"
puts "\nVerificando estado final..."

# Verificar se ainda há inconsistências
final_check = OrderService.joins(:order_service_proposals)
  .where(order_service_status_id: 4)
  .where(order_service_proposals: { order_service_proposal_status_id: [4, 5, 6, 7] })
  .distinct

puts "OSs ainda inconsistentes: #{final_check.count}"

if final_check.count == 0
  puts "✓ Todas as inconsistências foram corrigidas!"
else
  puts "⚠️ Ainda há #{final_check.count} OSs com problemas"
  final_check.limit(5).each do |os|
    puts "  - OS #{os.code}: Status OS=#{os.order_service_status_id}, Proposta=#{os.order_service_proposals.first&.order_service_proposal_status_id}"
  end
end
