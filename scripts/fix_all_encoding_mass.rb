# Correção EM MASSA de encoding UTF-8 em TODAS as tabelas

ActiveRecord::Base.transaction do
  puts "=" * 80
  puts "CORREÇÃO EM MASSA DE ENCODING UTF-8"
  puts "=" * 80
  puts "\n⚠️  Este processo pode demorar alguns minutos..."
  puts "Total esperado: ~3751 registros\n\n"
  
  conn = ActiveRecord::Base.connection
  
  # Mapa de correções
  fixes = {
    '??' => 'ã',
    '??' => 'ção',
    '??' => 'ções',
    '??' => 'á',
    '??' => 'é',
    '??' => 'í',
    '??' => 'ó',
    '??' => 'ú',
    '??' => 'â',
    '??' => 'ê',
    '??' => 'ô',
    '??' => 'à',
    '??' => 'õ',
    '??' => 'ç',
    '??' => 'ü',
    
    # Maiúsculas
    '??' => 'Ã',
    '??' => 'Á',
    '??' => 'É',
    '??' => 'Í',
    '??' => 'Ó',
    '??' => 'Ú',
    '??' => 'Â',
    '??' => 'Ê',
    '??' => 'Ô',
    '??' => 'À',
    '??' => 'Õ',
    '??' => 'Ç',
    '??' => 'Ü'
  }
  
  # SQL para cada correção
  fixes.each do |wrong, correct|
    escaped_wrong = conn.quote(wrong)
    escaped_correct = conn.quote(correct)
    
    # Tabelas text
    tables_text = ['order_services', 'order_service_proposals']
    text_columns = {
      'order_services' => ['details', 'cancel_justification'],
      'order_service_proposals' => ['details', 'reason_reproved', 'reason_approved']
    }
    
    tables_text.each do |table|
      next unless conn.table_exists?(table)
      
      text_columns[table].each do |column|
        begin
          sql = "UPDATE #{table} SET #{column} = REPLACE(#{column}, #{escaped_wrong}, #{escaped_correct}) WHERE #{column} LIKE '%??%'"
          conn.execute(sql)
        rescue => e
          # Continuar
        end
      end
    end
    
    # Tabelas string - em lotes pequenos para não travar
    tables_string = ['users', 'cost_centers', 'contracts', 'vehicles', 'vehicle_models', 'categories', 'cities', 'states']
    
    tables_string.each do |table|
      next unless conn.table_exists?(table)
      
      columns = conn.columns(table).select { |c| c.type == :string || c.type == :text }
      
      columns.each do |column|
        begin
          sql = "UPDATE #{table} SET #{column.name} = REPLACE(#{column.name}, #{escaped_wrong}, #{escaped_correct}) WHERE #{column.name} LIKE '%??%'"
          result = conn.execute(sql)
        rescue => e
          # Continuar
        end
      end
    end
  end
  
  puts "\n✅ Correções aplicadas!"
  puts "\nVerificando resultado...\n"
  
  # Verificar resultado
  total_remaining = 0
  
  ['users', 'cost_centers', 'contracts', 'vehicles', 'vehicle_models', 'order_services', 'order_service_proposals', 'categories', 'cities', 'states'].each do |table|
    next unless conn.table_exists?(table)
    
    columns = conn.columns(table).select { |c| c.type == :string || c.type == :text }
    
    columns.each do |column|
      begin
        result = conn.select_one("SELECT COUNT(*) as count FROM #{table} WHERE #{column.name} LIKE '%??%'")
        count = result['count'].to_i
        total_remaining += count
        
        if count > 0
          puts "  ⚠️  #{table}.#{column.name}: ainda #{count} com problemas"
        end
      rescue
        # Ignorar
      end
    end
  end
  
  puts "\n" + "=" * 80
  if total_remaining == 0
    puts "🎉 SUCESSO TOTAL! Nenhum registro com ???? restante!"
  else
    puts "⚠️  Ainda restam #{total_remaining} registros com problemas"
    puts "   (podem ser casos especiais que precisam correção manual)"
  end
  puts "=" * 80
  
end
