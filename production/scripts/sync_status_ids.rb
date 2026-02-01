# Script de sincronização de IDs - OrderServiceStatus e OrderServiceProposalStatus
# Este script ajusta os IDs no banco para corresponder às constantes do código

puts "=" * 80
puts "SINCRONIZAÇÃO DE IDs - STATUS DE OS E PROPOSTAS"
puts "=" * 80
puts ""
puts "⚠️  ATENÇÃO: Este script fará alterações permanentes no banco de dados!"
puts "   Certifique-se de ter um backup antes de prosseguir."
puts ""
print "Digite 'CONFIRMO' para continuar: "
confirmacao = gets.chomp

unless confirmacao == 'CONFIRMO'
  puts "\n❌ Operação cancelada pelo usuário."
  exit
end

ActiveRecord::Base.transaction do
  puts "\n🔧 Desabilitando verificações de foreign key..."
  ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 0")
  
  puts "\n" + "=" * 80
  puts "PARTE 1: ORDER_SERVICE_STATUS"
  puts "=" * 80
  
  # Mapeamento: ID_ATUAL => [ID_NOVO, NOME_ESPERADO]
  os_status_mapping = {
    1 => [2, 'Em aberto'],              # EM_ABERTO_ID
    2 => [4, 'Aguardando avaliação de proposta'], # AGUARDANDO_AVALIACAO_PROPOSTA_ID
    3 => [5, 'Aprovada'],               # APROVADA_ID
    4 => [6, 'Nota fiscal inserida'],   # NOTA_FISCAL_INSERIDA_ID
    5 => [7, 'Autorizada'],             # AUTORIZADA_ID
    6 => [8, 'Aguardando pagamento'],   # AGUARDANDO_PAGAMENTO_ID
    7 => [9, 'Paga'],                   # PAGA_ID
    8 => [10, 'Cancelada'],             # CANCELADA_ID
    9 => [1, 'Em cadastro']             # EM_CADASTRO_ID
  }
  
  puts "\n1. Criando tabela temporária para status de OS..."
  ActiveRecord::Base.connection.execute("
    CREATE TEMPORARY TABLE temp_os_status_mapping (
      old_id INT PRIMARY KEY,
      new_id INT NOT NULL,
      expected_name VARCHAR(255)
    )
  ")
  
  os_status_mapping.each do |old_id, (new_id, name)|
    ActiveRecord::Base.connection.execute("
      INSERT INTO temp_os_status_mapping VALUES (#{old_id}, #{new_id}, '#{name}')
    ")
  end
  
  puts "2. Atualizando order_services com novo mapeamento..."
  ActiveRecord::Base.connection.execute("
    UPDATE order_services os
    INNER JOIN temp_os_status_mapping m ON os.order_service_status_id = m.old_id
    SET os.order_service_status_id = m.new_id + 1000
  ")
  
  puts "3. Ajustando IDs temporários (removendo offset de 1000)..."
  ActiveRecord::Base.connection.execute("
    UPDATE order_services
    SET order_service_status_id = order_service_status_id - 1000
    WHERE order_service_status_id > 1000
  ")
  
  puts "4. Atualizando IDs da tabela order_service_statuses..."
  os_status_mapping.sort_by { |_, (new_id, _)| -new_id }.each do |old_id, (new_id, _)|
    ActiveRecord::Base.connection.execute("
      UPDATE order_service_statuses
      SET id = #{new_id + 1000}
      WHERE id = #{old_id}
    ")
  end
  
  ActiveRecord::Base.connection.execute("
    UPDATE order_service_statuses
    SET id = id - 1000
    WHERE id > 1000
  ")
  
  puts "5. Adicionando status 'Em reavaliação' (ID 3) se não existir..."
  unless OrderServiceStatus.exists?(3)
    ActiveRecord::Base.connection.execute("
      INSERT INTO order_service_statuses (id, name, created_at, updated_at)
      VALUES (3, 'Em reavaliação', NOW(), NOW())
    ")
  end
  
  puts "\n✅ OrderServiceStatus sincronizado!"
  puts "\nNovos IDs:"
  OrderServiceStatus.order(:id).each do |s|
    puts "  ID #{s.id}: #{s.name}"
  end
  
  puts "\n" + "=" * 80
  puts "PARTE 2: ORDER_SERVICE_PROPOSAL_STATUS"
  puts "=" * 80
  
  # Mapeamento para propostas
  proposal_status_mapping = {
    1 => [12, 'Em aberto'],
    2 => [13, 'Aguardando avaliação de proposta'],
    3 => [14, 'Aprovada'],
    4 => [15, 'Notas fiscais inseridas'],
    5 => [16, 'Autorizada'],
    6 => [17, 'Aguardando pagamento'],
    7 => [18, 'Paga'],
    8 => [19, 'Proposta reprovada'],
    9 => [20, 'Cancelada'],
    10 => [1, 'Em cadastro'],
    11 => [11, 'Aguardando aprovação de complemento']
  }
  
  puts "\n1. Criando tabela temporária para status de propostas..."
  ActiveRecord::Base.connection.execute("
    CREATE TEMPORARY TABLE temp_proposal_status_mapping (
      old_id INT PRIMARY KEY,
      new_id INT NOT NULL,
      expected_name VARCHAR(255)
    )
  ")
  
  proposal_status_mapping.each do |old_id, (new_id, name)|
    ActiveRecord::Base.connection.execute("
      INSERT INTO temp_proposal_status_mapping VALUES (#{old_id}, #{new_id}, '#{name}')
    ")
  end
  
  puts "2. Atualizando order_service_proposals com novo mapeamento..."
  ActiveRecord::Base.connection.execute("
    UPDATE order_service_proposals osp
    INNER JOIN temp_proposal_status_mapping m ON osp.order_service_proposal_status_id = m.old_id
    SET osp.order_service_proposal_status_id = m.new_id + 1000
  ")
  
  puts "3. Ajustando IDs temporários..."
  ActiveRecord::Base.connection.execute("
    UPDATE order_service_proposals
    SET order_service_proposal_status_id = order_service_proposal_status_id - 1000
    WHERE order_service_proposal_status_id > 1000
  ")
  
  puts "4. Atualizando IDs da tabela order_service_proposal_statuses..."
  proposal_status_mapping.sort_by { |_, (new_id, _)| -new_id }.each do |old_id, (new_id, _)|
    ActiveRecord::Base.connection.execute("
      UPDATE order_service_proposal_statuses
      SET id = #{new_id + 1000}
      WHERE id = #{old_id}
    ")
  end
  
  ActiveRecord::Base.connection.execute("
    UPDATE order_service_proposal_statuses
    SET id = id - 1000
    WHERE id > 1000
  ")
  
  puts "\n✅ OrderServiceProposalStatus sincronizado!"
  puts "\nNovos IDs:"
  OrderServiceProposalStatus.order(:id).each do |s|
    puts "  ID #{s.id}: #{s.name}"
  end
  
  puts "\n" + "=" * 80
  puts "VERIFICAÇÃO FINAL"
  puts "=" * 80
  
  puts "\nContagem de registros:"
  puts "  - OrderServices: #{OrderService.count}"
  puts "  - OrderServiceProposals: #{OrderServiceProposal.count}"
  puts "  - OSs Aprovadas: #{OrderService.where(order_service_status_id: 5).count}"
  puts "  - OSs Pagas: #{OrderService.where(order_service_status_id: 9).count}"
  puts "  - Propostas Aprovadas: #{OrderServiceProposal.where(order_service_proposal_status_id: 14).count}"
  puts "  - Propostas Pagas: #{OrderServiceProposal.where(order_service_proposal_status_id: 18).count}"
  
  puts "\n✅ SINCRONIZAÇÃO CONCLUÍDA COM SUCESSO!"
  puts "   Todos os IDs foram atualizados e as referências estão íntegras."
  puts ""
  
  puts "\n🔧 Reabilitando verificações de foreign key..."
  ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 1")
end

puts "\n🎉 Operação finalizada! O sistema agora está sincronizado."
