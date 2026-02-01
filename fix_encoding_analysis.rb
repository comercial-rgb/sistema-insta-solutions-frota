#!/usr/bin/env ruby
# Script para análise de problemas de encoding no banco

puts "=" * 80
puts "🔍 ANÁLISE DE ENCODING - Sistema Insta Solutions"
puts "=" * 80
puts ""

# Conexão do ActiveRecord
db_config = ActiveRecord::Base.connection_db_config.configuration_hash
puts "📊 Configuração do Banco:"
puts "  Charset: #{ActiveRecord::Base.connection.charset rescue 'N/A'}"
puts "  Collation: #{ActiveRecord::Base.connection.collation rescue 'N/A'}"
puts ""

# Exemplos de dados com encoding errado
problemas = {
  'Simêo' => 'Simão',
  'Joêo' => 'João',
  'Viêosa' => 'Viçosa',
  'Sêo' => 'São',
  'Mêrio' => 'Mário'
}

puts "🔍 Procurando problemas de encoding..."
puts ""

# Verificar tabelas principais
tables_to_check = [
  {model: City, field: :name, label: 'Cidades'},
  {model: PartService, field: :name, label: 'Peças/Serviços'},
  {model: User, field: :name, label: 'Usuários'},
  {model: User, field: :fantasy_name, label: 'Usuários (Nome Fantasia)'},
  {model: Provider, field: :name, label: 'Fornecedores'},
  {model: Vehicle, field: :model, label: 'Veículos (Modelo)'},
  {model: VehicleBrand, field: :name, label: 'Marcas de Veículos'},
  {model: VehicleModel, field: :name, label: 'Modelos de Veículos'},
  {model: PartServiceOrderService, field: :name, label: 'Itens de OS'}
]

stats = {total_checked: 0, total_with_issues: 0, tables_affected: 0}

tables_to_check.each do |table_config|
  model = table_config[:model]
  field = table_config[:field]
  label = table_config[:label]
  
  next unless model.column_names.include?(field.to_s)
  
  count_with_issues = 0
  examples = []
  
  model.where.not(field => nil).find_each do |record|
    value = record.send(field).to_s
    stats[:total_checked] += 1
    
    # Verificar se contém padrões problemáticos
    if value =~ /[êô]/i || value.match?(/\P{ASCII}/) 
      # Verificar se não é um acentohado legítimo em português
      if value.include?('ê') && !['três', 'você', 'inglês', 'português'].any? { |w| value.downcase.include?(w) }
        count_with_issues += 1
        examples << {id: record.id, value: value} if examples.size < 5
      elsif value.include?('ô') && !['avô', 'vovô', 'pônei'].any? { |w| value.downcase.include?(w) }
        count_with_issues += 1
        examples << {id: record.id, value: value} if examples.size < 5
      end
    end
  end
  
  if count_with_issues > 0
    stats[:total_with_issues] += count_with_issues
    stats[:tables_affected] += 1
    
    puts "❌ #{label} (#{model.name}):"
    puts "   Registros com problemas: #{count_with_issues}"
    puts "   Exemplos:"
    examples.each do |ex|
      puts "     ID #{ex[:id]}: \"#{ex[:value]}\""
    end
    puts ""
  else
    puts "✓ #{label}: OK (#{model.count} registros verificados)"
  end
end

puts "=" * 80
puts "📊 RESUMO"
puts "=" * 80
puts ""
puts "Total de registros verificados: #{stats[:total_checked]}"
puts "Registros com problemas: #{stats[:total_with_issues]}"
puts "Tabelas afetadas: #{stats[:tables_affected]}"
puts ""

if stats[:total_with_issues] > 0
  puts "⚠️  CORREÇÃO NECESSÁRIA!"
  puts ""
  puts "Execute o script de correção para resolver os problemas encontrados."
else
  puts "✅ Nenhum problema encontrado!"
end

puts "=" * 80
