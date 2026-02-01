# Verificar se os IDs estão corretos agora
puts '=== VERIFICAÇÃO DOS IDs APÓS CORREÇÃO ==='
puts "\nOrderServiceStatus IDs:"
puts "  EM_CADASTRO_ID: #{OrderServiceStatus::EM_CADASTRO_ID}"
puts "  EM_ABERTO_ID: #{OrderServiceStatus::EM_ABERTO_ID}"
puts "  EM_REAVALIACAO_ID: #{OrderServiceStatus::EM_REAVALIACAO_ID}"
puts "  AGUARDANDO_AVALIACAO_PROPOSTA_ID: #{OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID}"
puts "  APROVADA_ID: #{OrderServiceStatus::APROVADA_ID}"
puts "  NOTA_FISCAL_INSERIDA_ID: #{OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID}"
puts "  AUTORIZADA_ID: #{OrderServiceStatus::AUTORIZADA_ID}"
puts "  AGUARDANDO_PAGAMENTO_ID: #{OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID}"
puts "  PAGA_ID: #{OrderServiceStatus::PAGA_ID}"
puts "  CANCELADA_ID: #{OrderServiceStatus::CANCELADA_ID}"

puts "\nOrderServiceProposalStatus IDs:"
puts "  EM_CADASTRO_ID: #{OrderServiceProposalStatus::EM_CADASTRO_ID}"
puts "  AGUARDANDO_APROVACAO_COMPLEMENTO_ID: #{OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID}"
puts "  EM_ABERTO_ID: #{OrderServiceProposalStatus::EM_ABERTO_ID}"
puts "  AGUARDANDO_AVALIACAO_ID: #{OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID}"
puts "  APROVADA_ID: #{OrderServiceProposalStatus::APROVADA_ID}"
puts "  NOTAS_INSERIDAS_ID: #{OrderServiceProposalStatus::NOTAS_INSERIDAS_ID}"
puts "  AUTORIZADA_ID: #{OrderServiceProposalStatus::AUTORIZADA_ID}"
puts "  AGUARDANDO_PAGAMENTO_ID: #{OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID}"
puts "  PAGA_ID: #{OrderServiceProposalStatus::PAGA_ID}"
puts "  PROPOSTA_REPROVADA_ID: #{OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID}"
puts "  CANCELADA_ID: #{OrderServiceProposalStatus::CANCELADA_ID}"

# Verificar OSs específicas mencionadas pelo usuário
puts "\n\n=== VERIFICAÇÃO DAS OSs MENCIONADAS ==="
os1 = OrderService.find_by(code: 'OS42565202619')
if os1
  puts "\nOS42565202619 (ID: #{os1.id}):"
  puts "  Status da OS: #{os1.order_service_status&.name} (ID: #{os1.order_service_status_id})"
  puts "  Total de propostas: #{os1.order_service_proposals.count}"
  os1.order_service_proposals.each do |p|
    puts "    - Proposta ##{p.id}: #{p.order_service_proposal_status&.name} (ID: #{p.order_service_proposal_status_id})"
  end
  
  # Verificar se há inconsistência
  if os1.order_service_status_id == 4 # AGUARDANDO_AVALIACAO_PROPOSTA_ID agora é 4
    proposals_em_avaliacao = os1.order_service_proposals.where(order_service_proposal_status_id: 13).count
    if proposals_em_avaliacao == 0
      puts "  ⚠️ INCONSISTÊNCIA: OS está 'Aguardando avaliação' mas não tem propostas em avaliação!"
    else
      puts "  ✓ OK: Tem #{proposals_em_avaliacao} proposta(s) em avaliação"
    end
  end
end

os2 = OrderService.find_by(code: 'OS4234820251118')
if os2
  puts "\nOS4234820251118 (ID: #{os2.id}):"
  puts "  Status da OS: #{os2.order_service_status&.name} (ID: #{os2.order_service_status_id})"
  puts "  Total de propostas: #{os2.order_service_proposals.count}"
  os2.order_service_proposals.each do |p|
    puts "    - Proposta ##{p.id}: #{p.order_service_proposal_status&.name} (ID: #{p.order_service_proposal_status_id})"
  end
  
  # Verificar se há inconsistência
  if os2.order_service_status_id == 4 # AGUARDANDO_AVALIACAO_PROPOSTA_ID agora é 4
    proposals_em_avaliacao = os2.order_service_proposals.where(order_service_proposal_status_id: 13).count
    if proposals_em_avaliacao == 0
      puts "  ⚠️ INCONSISTÊNCIA: OS está 'Aguardando avaliação' mas não tem propostas em avaliação!"
    else
      puts "  ✓ OK: Tem #{proposals_em_avaliacao} proposta(s) em avaliação"
    end
  end
end

# Análise geral de inconsistências
puts "\n\n=== ANÁLISE DE INCONSISTÊNCIAS NO SISTEMA ==="

# OSs com proposta aprovada mas status diferente de APROVADA
inconsistent_approved = OrderService.joins(:order_service_proposals)
  .where(order_service_proposals: { order_service_proposal_status_id: 14 })
  .where.not(order_service_status_id: 5)
  .distinct

puts "\n1. OSs com proposta APROVADA mas status da OS != APROVADA: #{inconsistent_approved.count}"
inconsistent_approved.limit(5).each do |os|
  puts "  - OS #{os.code}: Status = #{os.order_service_status&.name} (ID: #{os.order_service_status_id})"
end

# OSs em "Aguardando avaliação" sem propostas aguardando
os_aguardando_sem_propostas = OrderService.left_joins(:order_service_proposals)
  .where(order_service_status_id: 4)
  .group('order_services.id')
  .having('SUM(CASE WHEN order_service_proposals.order_service_proposal_status_id = 13 THEN 1 ELSE 0 END) = 0')

puts "\n2. OSs em 'Aguardando avaliação' SEM propostas aguardando avaliação: #{os_aguardando_sem_propostas.count}"
os_aguardando_sem_propostas.limit(5).each do |os|
  total_propostas = os.order_service_proposals.count
  puts "  - OS #{os.code}: #{total_propostas} proposta(s), mas nenhuma em 'Aguardando avaliação'"
  os.order_service_proposals.each do |p|
    puts "      Status: #{p.order_service_proposal_status&.name}"
  end
end

puts "\n\n=== CORREÇÃO NECESSÁRIA ==="
if inconsistent_approved.count > 0 || os_aguardando_sem_propostas.count > 0
  puts "⚠️ Há inconsistências que precisam ser corrigidas!"
  puts "Recomendação: Executar script de correção automática"
else
  puts "✓ Nenhuma inconsistência detectada!"
end
