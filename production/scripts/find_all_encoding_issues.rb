# Buscar problemas de encoding diretamente no MySQL

conn = ActiveRecord::Base.connection

tables = [
  'users',
  'clients', 
  'cost_centers',
  'services',
  'service_groups',
  'contracts',
  'commitments',
  'providers',
  'vehicles',
  'vehicle_models',
  'order_services',
  'order_service_proposals',
  'categories',
  'cities',
  'states'
]

puts "=" * 80
puts "BUSCA DE ENCODING (????) EM TODAS AS TABELAS"
puts "=" * 80

total_found = 0

tables.each do |table|
  next unless conn.table_exists?(table)
  
  columns = conn.columns(table).select { |c| c.type == :string || c.type == :text }
  
  columns.each do |column|
    begin
      query = "SELECT COUNT(*) as count FROM #{table} WHERE #{column.name} LIKE '%??%'"
      result = conn.select_one(query)
      count = result['count'].to_i
      
      if count > 0
        puts "\n[#{table}.#{column.name}] #{count} registros com problemas"
        
        # Mostrar exemplos
        examples = conn.select_all("SELECT id, #{column.name} FROM #{table} WHERE #{column.name} LIKE '%??%' LIMIT 5")
        examples.each do |row|
          value = row[column.name].to_s.truncate(70)
          puts "  ID #{row['id']}: #{value}"
        end
        
        total_found += count
      end
    rescue => e
      # Ignorar erros
    end
  end
end

puts "\n" + "=" * 80
if total_found > 0
  puts "TOTAL DE REGISTROS COM PROBLEMAS: #{total_found}"
else
  puts "✓ NENHUM PROBLEMA ENCONTRADO"
end
puts "=" * 80
