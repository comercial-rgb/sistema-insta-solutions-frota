# CORREÇÃO EM MASSA - ENCODING Ü e î

puts "=" * 80
puts "CORREÇÃO EM MASSA DE ENCODING"
puts "=" * 80
puts "\nEste script irá corrigir:"
puts "  - Ü → ç"
puts "  - î → ç"
puts "\nTotal esperado: ~3.492 registros\n"

ActiveRecord::Base.transaction do
  conn = ActiveRecord::Base.connection
  
  # Função para corrigir via SQL direto
  def fix_table_column(conn, table, column)
    corrections = {
      'Ü' => 'ç',
      'î' => 'ç'
    }
    
    corrections.each do |wrong, correct|
      sql = "UPDATE #{table} SET #{column} = REPLACE(#{column}, '#{wrong}', '#{correct}') WHERE #{column} LIKE '%#{wrong}%'"
      conn.execute(sql)
    end
  end
  
  puts "\n1. Corrigindo USERS..."
  fix_table_column(conn, 'users', 'name')
  fix_table_column(conn, 'users', 'social_name')
  fix_table_column(conn, 'users', 'fantasy_name')
  puts "  ✓ Users corrigido"
  
  puts "\n2. Corrigindo CATEGORIES..."
  fix_table_column(conn, 'categories', 'name')
  puts "  ✓ Categories corrigido"
  
  puts "\n3. Corrigindo SERVICES..."
  fix_table_column(conn, 'services', 'name')
  fix_table_column(conn, 'services', 'description')
  puts "  ✓ Services corrigido"
  
  puts "\n4. Verificando resultado..."
  
  users_remaining = User.where("name LIKE '%Ü%' OR social_name LIKE '%Ü%' OR fantasy_name LIKE '%Ü%' OR name LIKE '%î%' OR social_name LIKE '%î%' OR fantasy_name LIKE '%î%'").count
  cat_remaining = Category.where("name LIKE '%Ü%' OR name LIKE '%î%'").count
  svc_remaining = Service.where("name LIKE '%Ü%' OR name LIKE '%î%'").count
  
  total_remaining = users_remaining + cat_remaining + svc_remaining
  
  puts "\n" + "=" * 80
  puts "RESULTADO"
  puts "=" * 80
  puts "Users com problemas: #{users_remaining}"
  puts "Categorias com problemas: #{cat_remaining}"
  puts "Services com problemas: #{svc_remaining}"
  puts "TOTAL RESTANTE: #{total_remaining}"
  
  if total_remaining == 0
    puts "\n🎉 SUCESSO TOTAL! Todos os registros corrigidos!"
  else
    puts "\n⚠️  Ainda há #{total_remaining} registros com problemas"
  end
  puts "=" * 80
end
