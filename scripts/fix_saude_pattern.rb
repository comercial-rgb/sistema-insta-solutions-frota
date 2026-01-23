# Corrigir SaÜde → Saúde e outros padrões restantes

puts "Corrigindo padrões específicos restantes..."

ActiveRecord::Base.transaction do
  conn = ActiveRecord::Base.connection
  
  # Correções específicas adicionais
  additional_fixes = {
    'SaÜde' => 'Saúde',
    'saÜde' => 'saúde',
    'SAîDE' => 'SAÚDE',
  }
  
  tables = ['cost_centers', 'contracts', 'users', 'services']
  
  tables.each do |table|
    # Obter todas as colunas de texto
    columns = conn.exec_query("SHOW COLUMNS FROM #{table}").select do |col|
      col['Type'].include?('varchar') || col['Type'].include?('text')
    end.map { |c| c['Field'] }
    
    puts "\n#{table.upcase}:"
    
    columns.each do |col|
      additional_fixes.each do |wrong, correct|
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

# Verificar resultado final
puts "\nVERIFICAÇÃO FINAL - COST CENTERS:"
CostCenter.where.not(name: nil).limit(25).each do |cc|
  puts "  ID #{cc.id}: #{cc.name}"
end
