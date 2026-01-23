# Detectar problemas de encoding em todas as tabelas

puts "=" * 80
puts "AUDITORIA COMPLETA DE ENCODING (????)"
puts "=" * 80

# Tabelas e colunas para verificar
tables_to_check = {
  'users' => ['name', 'email'],
  'clients' => ['name', 'corporate_name', 'address', 'neighborhood', 'city', 'state'],
  'cost_centers' => ['name', 'description'],
  'services' => ['name', 'description'],
  'service_groups' => ['name', 'description'],
  'contracts' => ['name', 'description', 'observations'],
  'commitments' => ['description', 'observations'],
  'providers' => ['name', 'corporate_name', 'address', 'neighborhood', 'city'],
  'vehicles' => ['plate', 'model', 'observations'],
  'vehicle_models' => ['name', 'brand'],
  'order_services' => ['observations', 'cancellation_reason'],
  'order_service_proposals' => ['observations', 'refused_reason'],
  'categories' => ['name', 'description'],
  'cities' => ['name'],
  'states' => ['name']
}

total_issues = 0
issues_by_table = {}

tables_to_check.each do |table_name, columns|
  next unless ActiveRecord::Base.connection.table_exists?(table_name)
  
  model_name = table_name.classify.constantize rescue nil
  next unless model_name
  
  columns.each do |column|
    next unless model_name.column_names.include?(column)
    
    records_with_issues = model_name.where("#{column} LIKE ?", '%??%')
    
    if records_with_issues.any?
      issues_by_table[table_name] ||= {}
      issues_by_table[table_name][column] = records_with_issues.count
      total_issues += records_with_issues.count
      
      puts "\n[#{table_name.upcase}] Coluna: #{column}"
      puts "   Total com problemas: #{records_with_issues.count}"
      
      # Mostrar primeiros 5 exemplos
      records_with_issues.limit(5).each do |record|
        value = record.send(column).to_s
        puts "   ID #{record.id}: #{value.truncate(60)}"
      end
    end
  end
end

puts "\n" + "=" * 80
puts "RESUMO"
puts "=" * 80

if total_issues > 0
  puts "Total de registros com problemas: #{total_issues}"
  puts "\nPor tabela:"
  issues_by_table.each do |table, columns|
    count = columns.values.sum
    puts "  #{table}: #{count} registros"
    columns.each do |col, cnt|
      puts "    - #{col}: #{cnt}"
    end
  end
else
  puts "✓ Nenhum problema de encoding encontrado!"
end

puts "=" * 80
