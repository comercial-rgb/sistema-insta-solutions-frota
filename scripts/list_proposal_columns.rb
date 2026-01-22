puts 'Colunas da tabela order_service_proposals:'
OrderServiceProposal.column_names.sort.each { |col| puts "  - #{col}" }
