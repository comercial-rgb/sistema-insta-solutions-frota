#!/usr/bin/env ruby
# Script para correção de encoding UTF-8 no banco de dados

puts "=" * 80
puts "🔧 CORREÇÃO DE ENCODING - Banco de Dados"
puts "=" * 80
puts ""

# Mapeamento de correções
fixes = {
  'ê' => 'ã', # Simêo -> Simão, Joêo -> João
  'ô' => 'ã', # Can be São sometimes
}

# Padrões problemáticos mais específicos
specific_fixes = [
  {from: /sim[eê]o/i, to: 'Simão'},
  {from: /jo[eê]o/i, to: 'João'},
  {from: /vi[çc][oô]sa/i, to: 'Viçosa'},
  {from: /s[eê]o\s/i, to: 'São '},
  {from: /m[aá]rio/i, to: 'Mário'},
  {from: /Jos[eê]\s/i, to: 'José '},
  {from: /Maria\s/i, to: 'Maria '},
]

# Tabelas e campos para verificar
tables_to_fix = [
  {model: City, fields: [:name], label: 'Cidades'},
  {model: PartServiceOrderService, fields: [:name, :brand, :observation], label: 'Itens de OS (Peças/Serviços em Garantia)'},
  {model: User, fields: [:name, :fantasy_name], label: 'Usuários e Fornecedores'},
  {model: Vehicle, fields: [:model, :brand, :board], label: 'Veículos'},
  {model: VehicleModel, fields: [:name], label: 'Modelos de Veículos'},
]

stats = {
  total_checked: 0,
  total_fixed: 0,
  tables_affected: 0
}

tables_to_fix.each do |config|
  model = config[:model]
  fields = config[:fields]
  label = config[:label]
  
  puts "🔍 Verificando: #{label}"
  
  table_fixes = 0
  
  model.find_each do |record|
    fields.each do |field|
      next unless record.respond_to?(field)
      
      original_value = record.send(field).to_s
      next if original_value.blank?
      
      stats[:total_checked] += 1
      new_value = original_value.dup
      
      # Aplicar correções específicas
      specific_fixes.each do |fix|
        new_value.gsub!(fix[:from]) do |match|
          # Preservar capitalização
          if match[0] == match[0].upcase
            fix[:to].capitalize
          else
            fix[:to].downcase
          end
        end
      end
      
      # Se houve alteração, atualizar
      if new_value != original_value
        puts "  ✏️  ID #{record.id}: \"#{original_value}\" -> \"#{new_value}\""
        
        begin
          record.update_column(field, new_value)
          table_fixes += 1
          stats[:total_fixed] += 1
        rescue => e
          puts "  ❌ Erro ao atualizar: #{e.message}"
        end
      end
    end
  end
  
  if table_fixes > 0
    stats[:tables_affected] += 1
    puts "  ✅ #{table_fixes} registros corrigidos"
  else
    puts "  ✓ Nenhuma correção necessária"
  end
  
  puts ""
end

puts "=" * 80
puts "📊 RESUMO FINAL"
puts "=" * 80
puts ""
puts "Registros verificados: #{stats[:total_checked]}"
puts "Registros corrigidos: #{stats[:total_fixed]}"
puts "Tabelas afetadas: #{stats[:tables_affected]}"
puts ""

if stats[:total_fixed] > 0
  puts "✅ Correções aplicadas com sucesso!"
  puts ""
  puts "⚠️  IMPORTANTE: Limpe o cache do Rails se necessário:"
  puts "   Rails.cache.clear"
else
  puts "✓ Nenhuma correção necessária!"
end

puts "=" * 80
