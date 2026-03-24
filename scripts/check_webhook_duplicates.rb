# Script simplificado para verificar duplicatas e encoding
puts "=" * 70
puts "VERIFICACAO DE DUPLICATAS E ENCODING"
puts "=" * 70

# 1. Verificar duplicatas via SQL direto
puts "\n--- DUPLICATAS DE CODIGO ---"
dups = ActiveRecord::Base.connection.execute(
  "SELECT code, COUNT(*) as cnt FROM order_services GROUP BY code HAVING cnt > 1 ORDER BY cnt DESC LIMIT 20"
)
dup_count = 0
dups.each do |row|
  dup_count += 1
  puts "  #{row[0]}: #{row[1]}x"
end
puts "Total codigos duplicados: #{dup_count}"
puts "(0 = webhook NAO criou duplicatas)" if dup_count == 0

# 2. Verificar encoding de fornecedores
puts "\n--- FORNECEDORES COM VARIACAO DE ESTETICA/ETOTICA ---"
results = ActiveRecord::Base.connection.execute(
  "SELECT id, fantasy_name, name, social_name FROM users WHERE profile_id = 6 AND (fantasy_name LIKE '%st%tica%' OR fantasy_name LIKE '%t%tica%' OR name LIKE '%st%tica%') ORDER BY fantasy_name"
)
results.each do |row|
  puts "  ID: #{row[0]} | fantasy_name: '#{row[1]}' | name: '#{row[2]}' | social_name: '#{row[3]}'"
end

# 3. Buscar todos os fornecedores ativos para referencia
puts "\n--- TODOS OS FORNECEDORES ATIVOS ---"
results = ActiveRecord::Base.connection.execute(
  "SELECT id, fantasy_name FROM users WHERE profile_id = 6 AND user_status_id = 2 ORDER BY fantasy_name"
)
results.each do |row|
  puts "  ID: #{row[0]} | #{row[1]}"
end

puts "\n" + "=" * 70
puts "Concluido em #{Time.now.strftime('%d/%m/%Y %H:%M')}"
puts "=" * 70
