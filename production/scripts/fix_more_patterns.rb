# Correção de mais padrões Ü encontrados

puts "Corrigindo padrões adicionais..."

ActiveRecord::Base.transaction do
  conn = ActiveRecord::Base.connection
  
  more_fixes = {
    # Novos padrões encontrados
    'GestÜo' => 'Gestão',
    'gestÜo' => 'gestão',
    'GESTîO' => 'GESTÃO',
    
    'SuperintendÜncia' => 'Superintendência',
    'superintendÜncia' => 'superintendência',
    'SUPERINTENDîNCIA' => 'SUPERINTENDÊNCIA',
    
    'PraÜa' => 'Praça',
    'praÜa' => 'praça',
    'PRAîA' => 'PRAÇA',
    
    'nÜmero' => 'número',
    'NÜmero' => 'Número',
    'NîMERO' => 'NÚMERO',
    'nÜ.' => 'nº.',
    'NÜ.' => 'Nº.',
    'nÜ' => 'nº',
    'NÜ' => 'Nº',
    
    'AmÜrico' => 'Américo',
    'amÜrico' => 'américo',
    'AMîRICO' => 'AMÉRICO',
    
    # Outros comuns
    'EmpresarialÜ' => 'Empresarial',
    'empresarial' => 'empresarial',
  }
  
  # Aplicar apenas em colunas que contêm nomes/endereços  
  tables_cols = {
    'cost_centers' => ['name', 'invoice_name', 'invoice_address', 'invoice_fantasy_name'],
    'contracts' => ['name', 'contract_object'],
    'users' => ['name', 'social_name', 'fantasy_name', 'address'],
  }
  
  tables_cols.each do |table, cols|
    puts "\n#{table.upcase}:"
    cols.each do |col|
      more_fixes.each do |wrong, correct|
        result = conn.exec_query("SELECT COUNT(*) as cnt FROM #{table} WHERE #{col} LIKE '%#{wrong}%'")
        count = result.first['cnt']
        
        if count > 0
          conn.execute("UPDATE #{table} SET #{col} = REPLACE(#{col}, '#{wrong}', '#{correct}') WHERE #{col} LIKE '%#{wrong}%'")
          puts "  #{col}: #{wrong} → #{correct} (#{count})"
        end
      end
    end
  end
end

puts "\n✓ Correções aplicadas!"
puts "\nExemplos corrigidos:"
puts "\nCOST CENTERS:"
conn = ActiveRecord::Base.connection
conn.exec_query("SELECT id, name FROM cost_centers WHERE name IS NOT NULL LIMIT 20").each do |row|
  puts "  #{row['id']}: #{row['name']}"
end
