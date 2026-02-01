# Verificar e corrigir TODAS as tabelas com encoding

puts "=" * 80
puts "CORREÇÃO EM MASSA - TODAS AS TABELAS"
puts "=" * 80

# Lista de palavras com correções conhecidas
word_fixes = {
  # Palavras mencionadas pelo usuário
  'Educaçço' => 'Educação',
  'educaçço' => 'educação',
  'EDUCAççO' => 'EDUCAÇÃO',
  'Educaçço' => 'Educação',
  'Ibiraçu' => 'Ibiraçu',  # já está correto
  'Saçde' => 'Saúde',
  'saçde' => 'saúde',
  'SAçDE' => 'SAÚDE',
  'Conceiçço' => 'Conceição',
  'conceiçço' => 'conceição',
  'CONCEIççO' => 'CONCEIÇÃO',
  'Vigilçncia' => 'Vigilância',
  'vigilçncia' => 'vigilância',
  'VIGILçNCIA' => 'VIGILÂNCIA',
  'Atençço' => 'Atenção',
  'atençço' => 'atenção',
  'ATENççO' => 'ATENÇÃO',
  'Administraçço' => 'Administração',
  'administraçço' => 'administração',
  'ADMINISTRAççO' => 'ADMINISTRAÇÃO',
  'Assistçncia' => 'Assistência',
  'assistçncia' => 'assistência',
  'ASSISTçNCIA' => 'ASSISTÊNCIA',
  'Fundço' => 'Fundão',
  'fundço' => 'fundão',
  'FUNDçO' => 'FUNDÃO',
  'Serviços' => 'Serviços', # já correto
  
  # Adicionar mais correções baseadas no padrão ç em vez de ã ou ó
  'Administraçço' => 'Administração',
  'Prevençço' => 'Prevenção',
  'prevençço' => 'prevenção',
  'Saçde' => 'Saúde',
}

ActiveRecord::Base.transaction do
  conn = ActiveRecord::Base.connection
  
  # Tabelas e colunas a corrigir
  tables_columns = {
    'cost_centers' => ['name', 'description', 'invoice_name', 'invoice_fantasy_name'],
    'contracts' => ['contract_object'],  # assumindo que existe
    'users' => ['name', 'social_name', 'fantasy_name'],
    'services' => ['name', 'description'],
  }
  
  total_fixes = 0
  
  tables_columns.each do |table, columns|
    puts "\n#{table.upcase}:"
    
    columns.each do |col|
      # Verificar se a coluna existe
      col_exists = conn.exec_query("SHOW COLUMNS FROM #{table} LIKE '#{col}'").any?
      next unless col_exists
      
      word_fixes.each do |wrong, correct|
        next if wrong == correct
        
        # Contar quantos registros serão afetados
        result = conn.exec_query("SELECT COUNT(*) as cnt FROM #{table} WHERE #{col} LIKE '%#{wrong}%'")
        count = result.first['cnt']
        
        if count > 0
          # Aplicar correção
          conn.execute("UPDATE #{table} SET #{col} = REPLACE(#{col}, '#{wrong}', '#{correct}') WHERE #{col} LIKE '%#{wrong}%'")
          puts "  #{col}: #{wrong} → #{correct} (#{count} registros)"
          total_fixes += count
        end
      end
    end
  end
  
  puts "\n" + "=" * 80
  puts "✓ #{total_fixes} correções aplicadas!"
  puts "=" * 80
  
  # Mostrar alguns exemplos
  puts "\nExemplos de COST CENTERS:"
  conn.exec_query("SELECT id, name FROM cost_centers LIMIT 10").each do |row|
    puts "  ID #{row['id']}: #{row['name']}"
  end
end
