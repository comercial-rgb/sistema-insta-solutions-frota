# Verificação final completa de todas as tabelas

puts "=" * 80
puts "VERIFICAÇÃO FINAL - TODAS AS TABELAS"
puts "=" * 80

# Buscar qualquer Ü ou î restante
tables = ['cost_centers', 'contracts', 'users', 'services']

total_problems = 0

tables.each do |table|
  conn = ActiveRecord::Base.connection
  
  # Obter colunas de texto
  columns = conn.exec_query("SHOW COLUMNS FROM #{table}").select do |col|
    col['Type'].include?('varchar') || col['Type'].include?('text')
  end.map { |c| c['Field'] }
  
  puts "\n#{table.upcase}:"
  table_problems = 0
  
  columns.each do |col|
    # Buscar Ü ou î ou ÜÜ
    result = conn.exec_query("SELECT COUNT(*) as cnt FROM #{table} WHERE #{col} LIKE '%Ü%' OR #{col} LIKE '%î%'")
    count = result.first['cnt']
    
    if count > 0
      puts "  #{col}: #{count} registros com Ü ou î"
      table_problems += count
      
      # Mostrar exemplos
      examples = conn.exec_query("SELECT id, #{col} FROM #{table} WHERE #{col} LIKE '%Ü%' OR #{col} LIKE '%î%' LIMIT 5")
      examples.each do |row|
        puts "    ID #{row['id']}: #{row[col]}"
      end
    end
  end
  
  if table_problems == 0
    puts "  ✅ Nenhum problema encontrado!"
  else
    total_problems += table_problems
  end
end

puts "\n" + "=" * 80
if total_problems == 0
  puts "✅✅✅ PERFEITO! Nenhum problema de encoding restante!"
else
  puts "⚠️ Ainda há #{total_problems} registros com problemas"
end
puts "=" * 80

# Mostrar exemplos de registros corrigidos
puts "\nEXEMPLOS DE REGISTROS CORRIGIDOS:"

puts "\nCOST CENTERS:"
CostCenter.where("name LIKE '%ção%' OR name LIKE '%ência%' OR name LIKE '%ção%'").limit(10).each do |cc|
  puts "  ✓ #{cc.name}"
end

puts "\nUSERS (com palavras específicas):"
User.where("fantasy_name LIKE '%ção%' OR fantasy_name LIKE '%Saúde%' OR social_name LIKE '%ção%'").limit(10).each do |u|
  puts "  ✓ #{u.fantasy_name || u.social_name}"
end
