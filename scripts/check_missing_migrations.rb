# Verifica migrations marcadas como "up" mas que podem ter tabelas/colunas faltando

puts "Verificando integridade das migrations..."
puts "=" * 80

# Lista de migrations que criamos manualmente
manual_fixes = [
  'commitment_cost_centers',
  'reference_prices',
  'vehicle_models'
]

puts "\nTabelas criadas manualmente (já corrigidas):"
manual_fixes.each do |table|
  exists = ActiveRecord::Base.connection.table_exists?(table)
  puts "  #{exists ? '✅' : '❌'} #{table}"
end

puts "\nVerificando outras tabelas importantes..."

critical_tables = {
  'order_services' => %w[
    is_complement
    parent_proposal_id  
    reevaluation_requested_at
    reevaluation_requested_by_id
  ],
  'order_service_proposals' => %w[
    reason_refused_approval
    refused_by_manager_id
    refused_by_manager_at
    is_complement
    parent_proposal_id
  ],
  'vehicles' => %w[
    vehicle_model_id
    model_text_normalized
  ]
}

missing_columns = []

critical_tables.each do |table, columns|
  puts "\n#{table.upcase}:"
  columns.each do |column|
    exists = ActiveRecord::Base.connection.column_exists?(table, column)
    status = exists ? '✅' : '❌'
    puts "  #{status} #{column}"
    missing_columns << "#{table}.#{column}" unless exists
  end
end

if missing_columns.any?
  puts "\n" + "=" * 80
  puts "⚠️  COLUNAS FALTANDO:"
  puts "=" * 80
  missing_columns.each { |col| puts "  - #{col}" }
else
  puts "\n" + "=" * 80
  puts "✅ TODAS AS COLUNAS CRÍTICAS ESTÃO PRESENTES!"
  puts "=" * 80
end

puts "\nTotal de tabelas no banco: #{ActiveRecord::Base.connection.tables.count}"
puts "Total de migrations executadas: #{ActiveRecord::SchemaMigration.count}"
