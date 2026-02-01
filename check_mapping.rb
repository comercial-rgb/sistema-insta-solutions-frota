# Verificar mapeamento de IDs entre banco e aplicação
puts '=== MAPEAMENTO DE IDs NO BANCO ===\n'

puts "OrderServiceStatus (IDs no banco):"
OrderServiceStatus.all.order(:id).each do |status|
  puts "  #{status.id} - #{status.name}"
end

puts "\nOrderServiceProposalStatus (IDs no banco):"
OrderServiceProposalStatus.all.order(:id).each do |status|
  puts "  #{status.id} - #{status.name}"
end

puts "\n\n=== IDs DEFINIDOS NA APLICAÇÃO ===\n"
puts "OrderServiceStatus:"
puts "  EM_CADASTRO: #{OrderServiceStatus::EM_CADASTRO_ID}"
puts "  EM_ABERTO: #{OrderServiceStatus::EM_ABERTO_ID}"
puts "  EM_REAVALIACAO: #{OrderServiceStatus::EM_REAVALIACAO_ID}"
puts "  AGUARDANDO_AVALIACAO_PROPOSTA: #{OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID}"
puts "  APROVADA: #{OrderServiceStatus::APROVADA_ID}"
puts "  NOTA_FISCAL_INSERIDA: #{OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID}"
puts "  AUTORIZADA: #{OrderServiceStatus::AUTORIZADA_ID}"
puts "  AGUARDANDO_PAGAMENTO: #{OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID}"
puts "  PAGA: #{OrderServiceStatus::PAGA_ID}"
puts "  CANCELADA: #{OrderServiceStatus::CANCELADA_ID}"

puts "\nOrderServiceProposalStatus:"
puts "  EM_CADASTRO: #{OrderServiceProposalStatus::EM_CADASTRO_ID}"
puts "  AGUARDANDO_APROVACAO_COMPLEMENTO: #{OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID}"
puts "  EM_ABERTO: #{OrderServiceProposalStatus::EM_ABERTO_ID}"
puts "  AGUARDANDO_AVALIACAO: #{OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID}"
puts "  APROVADA: #{OrderServiceProposalStatus::APROVADA_ID}"
puts "  NOTAS_INSERIDAS: #{OrderServiceProposalStatus::NOTAS_INSERIDAS_ID}"
puts "  AUTORIZADA: #{OrderServiceProposalStatus::AUTORIZADA_ID}"
puts "  AGUARDANDO_PAGAMENTO: #{OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID}"
puts "  PAGA: #{OrderServiceProposalStatus::PAGA_ID}"
puts "  PROPOSTA_REPROVADA: #{OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID}"
puts "  CANCELADA: #{OrderServiceProposalStatus::CANCELADA_ID}"
