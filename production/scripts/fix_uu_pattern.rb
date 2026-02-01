# Correção específica para ÜÜ → ção

puts "=" * 80
puts "CORREÇÃO - PADRÃO ÜÜ"
puts "=" * 80

ActiveRecord::Base.transaction do
  conn = ActiveRecord::Base.connection
  
  # Mapeamento específico para o padrão ÜÜ
  fixes = {
    'educaÜÜo' => 'educação',
    'educaÜço' => 'educação',
    'EducaÜÜo' => 'Educação',
    'EducaÜço' => 'Educação',
    'EDUCAÜÜo' => 'EDUCAÇÃO',
    'EDUCAÜço' => 'EDUCAÇÃO',
    'EDUCAÜÜO' => 'EDUCAÇÃO',
    'EDUCAÜçO' => 'EDUCAÇÃO',
    
    'administraÜÜo' => 'administração',
    'administraÜço' => 'administração',
    'AdministraÜÜo' => 'Administração',
    'AdministraÜço' => 'Administração',
    'ADMINISTRAÜÜo' => 'ADMINISTRAÇÃO',
    'ADMINISTRAÜço' => 'ADMINISTRAÇÃO',
    'ADMINISTRAÜÜO' => 'ADMINISTRAÇÃO',
    'ADMINISTRAÜçO' => 'ADMINISTRAÇÃO',
    
    'integraÜÜo' => 'integração',
    'IntegraÜÜo' => 'Integração',
    'INTEGRAÜÜo' => 'INTEGRAÇÃO',
    'INTEGRAÜÜO' => 'INTEGRAÇÃO',
    
    'FinanÜas' => 'Finanças',
    'finanÜas' => 'finanças',
    'FINANÜas' => 'FINANÇAS',
    'FINANÜaS' => 'FINANÇAS',
    
    'ConservaÜÜo' => 'Conservação',
    'conservaÜÜo' => 'conservação',
    'CONSERVAÜÜo' => 'CONSERVAÇÃO',
    'CONSERVAÜÜO' => 'CONSERVAÇÃO',
    
    'saçde' => 'saúde',
    'Saçde' => 'Saúde',
    'SAçDE' => 'SAÚDE',
    
    'vigilçncia' => 'vigilância',
    'Vigilçncia' => 'Vigilância',
    'VIGILçNCIA' => 'VIGILÂNCIA',
    
    'atençço' => 'atenção',
    'Atençço' => 'Atenção',
    'ATENççO' => 'ATENÇÃO',
    
    'assistçncia' => 'assistência',
    'Assistçncia' => 'Assistência',
    'ASSISTçNCIA' => 'ASSISTÊNCIA',
    
    'prevençço' => 'prevenção',
    'Prevençço' => 'Prevenção',
    'PREVENççO' => 'PREVENÇÃO',
  }
  
  # Aplicar em várias tabelas
  tables = {
    'cost_centers' => ['name', 'description', 'invoice_name', 'invoice_fantasy_name'],
    'contracts' => ['name', 'contract_object', 'description'],
    'users' => ['name', 'social_name', 'fantasy_name'],
    'services' => ['name', 'description'],
    'commitments' => ['commitment_number'],  # pode ter descrições
  }
  
  total_fixes = 0
  
  tables.each do |table, columns|
    puts "\n#{table.upcase}:"
    
    columns.each do |col|
      # Verificar se coluna existe
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
  puts "✓ TOTAL: #{total_fixes} correções"
  puts "=" * 80
  
  # Verificar resultado
  puts "\nCOST CENTERS corrigidos:"
  conn.exec_query("SELECT id, name FROM cost_centers WHERE name IS NOT NULL LIMIT 15").each do |row|
    puts "  ID #{row['id']}: #{row['name']}"
  end
end
