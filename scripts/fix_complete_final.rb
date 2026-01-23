# Correção final - todos os padrões de Ü e î restantes

puts "=" * 80
puts "CORREÇÃO FINAL COMPLETA"
puts "=" * 80

ActiveRecord::Base.transaction do
  conn = ActiveRecord::Base.connection
  
  # Mapeamento completo de TODOS os padrões
  fixes = {
    # Padrão Ü → ê
    'AssistÜncia' => 'Assistência',
    'assistÜncia' => 'assistência',
    'ASSISTîNCIA' => 'ASSISTÊNCIA',
    
    'PrevidÜncia' => 'Previdência',
    'previdÜncia' => 'previdência',
    'PREVIDîNCIA' => 'PREVIDÊNCIA',
    
    'ResidÜncia' => 'Residência',
    'residÜncia' => 'residência',
    'RESIDîNCIA' => 'RESIDÊNCIA',
    
    'TransparÜncia' => 'Transparência',
    'transparÜncia' => 'transparência',
    'TRANSPARîNCIA' => 'TRANSPARÊNCIA',
    
    'AgÜncia' => 'Agência',
    'agÜncia' => 'agência',
    'AGîNCIA' => 'AGÊNCIA',
    
    'ViolÜncia' => 'Violência',
    'violÜncia' => 'violência',
    'VIOLîNCIA' => 'VIOLÊNCIA',
    
    'VigilÜncia' => 'Vigilância',
    'vigilÜncia' => 'vigilância',
    'VIGILîNCIA' => 'VIGILÂNCIA',
    
    'EmergÜncia' => 'Emergência',
    'emergÜncia' => 'emergência',
    'EMERGîNCIA' => 'EMERGÊNCIA',
    
    'InfÜncia' => 'Infância',
    'infÜncia' => 'infância',
    'INFîNCIA' => 'INFÂNCIA',
    
    # Padrão î → ó ou Ç
    'AtenÜÜo' => 'Atenção',
    'atençço' => 'atenção',
    'Atençço' => 'Atenção',
    'ATENîO' => 'ATENÇÃO',
    'ATENççO' => 'ATENÇÃO',
    
    'PrevençÜo' => 'Prevenção',
    'prevençÜo' => 'prevenção',
    'prevençço' => 'prevenção',
    'PREVENîO' => 'PREVENÇÃO',
    'PREVENççO' => 'PREVENÇÃO',
    
    'ConceiçÜo' => 'Conceição',
    'conceiçÜo' => 'conceição',
    'conceiçço' => 'conceição',
    'CONCEIîO' => 'CONCEIÇÃO',
    'CONCEIççO' => 'CONCEIÇÃO',
    
    'SaÞde' => 'Saúde',
    'saÞde' => 'saúde',
    'SAîDE' => 'SAÚDE',
    
    # Nomes de cidades
    'IbiraÜu' => 'Ibiraçu',
    'ibiraÜu' => 'ibiraçu',
    'IBIRAîU' => 'IBIRAÇU',
    
    'FundÜo' => 'Fundão',
    'fundÜo' => 'fundão',
    'FUNDîO' => 'FUNDÃO',
    
    # Outros padrões comuns
    'ConstruÜÜo' => 'Construção',
    'construÜÜo' => 'construção',
    'CONSTRUîO' => 'CONSTRUÇÃO',
    'CONSTRUççO' => 'CONSTRUÇÃO',
    
    'PopulaÜÜo' => 'População',
    'populaÜÜo' => 'população',
    'POPULAîO' => 'POPULAÇÃO',
    'POPULAççO' => 'POPULAÇÃO',
    
    'PromoÜÜo' => 'Promoção',
    'promoÜÜo' => 'promoção',
    'PROMOîO' => 'PROMOÇÃO',
    'PROMOççO' => 'PROMOÇÃO',
    
    'OperaÜÜo' => 'Operação',
    'operaÜÜo' => 'operação',
    'OPERAîO' => 'OPERAÇÃO',
    'OPERAççO' => 'OPERAÇÃO',
  }
  
  # Tabelas a corrigir
  tables = {
    'cost_centers' => ['name', 'description', 'invoice_name', 'invoice_fantasy_name', 'invoice_address'],
    'contracts' => ['name', 'contract_object', 'description'],
    'users' => ['name', 'social_name', 'fantasy_name', 'address'],
    'services' => ['name', 'description'],
  }
  
  total_fixes = 0
  
  tables.each do |table, columns|
    puts "\n#{table.upcase}:"
    
    columns.each do |col|
      col_exists = conn.exec_query("SHOW COLUMNS FROM #{table} LIKE '#{col}'").any?
      next unless col_exists
      
      fixes.each do |wrong, correct|
        result = conn.exec_query("SELECT COUNT(*) as cnt FROM #{table} WHERE #{col} LIKE '%#{wrong}%'")
        count = result.first['cnt']
        
        if count > 0
          conn.execute("UPDATE #{table} SET #{col} = REPLACE(#{col}, '#{wrong}', '#{correct}') WHERE #{col} LIKE '%#{wrong}%'")
          puts "  #{col}: #{wrong} → #{correct} (#{count})"
          total_fixes += count
        end
      end
    end
  end
  
  puts "\n" + "=" * 80
  puts "✓ TOTAL: #{total_fixes} correções aplicadas"
  puts "=" * 80
  
  # Verificação final
  puts "\nVERIFICANDO COST CENTERS:"
  conn.exec_query("SELECT id, name FROM cost_centers WHERE name IS NOT NULL ORDER BY id LIMIT 20").each do |row|
    puts "  ID #{row['id']}: #{row['name']}"
  end
end
