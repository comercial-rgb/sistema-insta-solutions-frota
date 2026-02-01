#!/usr/bin/env ruby
# Script para verificar erros de encoding em todas as tabelas do sistema

require_relative 'config/environment'

puts "🔍 VERIFICANDO ERROS DE ENCODING NO BANCO DE DADOS"
puts "=" * 80

# Padrões de erros conhecidos de encoding UTF-8 corrompido
# Estes padrões representam caracteres acentuados que foram mal interpretados
ENCODING_PATTERNS = {
  'ê' => ['â', 'ã', 'á', 'à'],  # Simêo -> Simão, Joêo -> João
  'ô' => ['ó', 'õ'],            # Sêo -> São
  'ê' => ['é'],                 # Mêrio -> Mário
  'ç' => ['ç'],                 # Viêosa -> Viçosa
  'í' => ['í'],
  'ú' => ['ú'],
  'Ê' => ['Â', 'Ã', 'Á', 'À'],
  'Ô' => ['Ó', 'Õ'],
  'Ê' => ['É'],
  'Ç' => ['Ç']
}

# Regex para detectar padrões de encoding corrompido
CORRUPTED_PATTERN = /[êôûãõáéíóúâêîôûàèìòùÊÔÛÃÕÁÉÍÓÚÂÊÎÔÛÀÈÌÒÙçÇ]{2,}|ê[osmn]|ô[aes]|Sê|Jê|Mê|Viê/i

def check_table(table_name, columns)
  puts "\n📋 Verificando tabela: #{table_name}"
  puts "-" * 80
  
  total_records = 0
  corrupted_records = []
  
  begin
    model_class = table_name.classify.constantize rescue nil
    
    if model_class.nil?
      puts "⚠️  Model não encontrado para #{table_name}, pulando..."
      return
    end
    
    total_records = model_class.count
    
    columns.each do |column|
      puts "  Verificando coluna: #{column}..."
      
      # Buscar registros com padrões suspeitos
      records = model_class.where.not(column => nil)
                          .where("#{column} REGEXP ?", CORRUPTED_PATTERN.source)
      
      records.each do |record|
        value = record.send(column)
        next if value.blank?
        
        if value.match?(CORRUPTED_PATTERN)
          corrupted_records << {
            id: record.id,
            column: column,
            value: value,
            table: table_name
          }
        end
      end
    end
    
    if corrupted_records.any?
      puts "\n  ❌ ENCONTRADOS #{corrupted_records.size} registros com problemas:"
      corrupted_records.each do |r|
        puts "    ID #{r[:id]} | #{r[:column]}: #{r[:value]}"
      end
    else
      puts "  ✅ Nenhum problema encontrado (#{total_records} registros verificados)"
    end
    
  rescue => e
    puts "  ⚠️  Erro ao verificar: #{e.message}"
  end
  
  corrupted_records
end

# Definir tabelas e colunas para verificar
TABLES_TO_CHECK = {
  'users' => ['name', 'fantasy_name', 'social_name'],
  'cities' => ['name'],
  'states' => ['name'],
  'services' => ['name', 'description', 'brand'],
  'vehicle_models' => ['brand', 'model', 'version', 'full_name'],
  'vehicles' => ['plate', 'renavam'],
  'providers' => [],  # Providers são users
  'addresses' => ['address', 'district', 'complement'],
  'maintenance_plans' => ['name', 'description'],
  'provider_service_types' => ['name'],
  'cost_centers' => ['name'],
  'sub_units' => ['name'],
  'service_groups' => ['name', 'description']
}

all_corrupted = []

TABLES_TO_CHECK.each do |table, columns|
  next if columns.empty?
  corrupted = check_table(table, columns)
  all_corrupted.concat(corrupted) if corrupted
end

puts "\n" + "=" * 80
puts "📊 RESUMO FINAL"
puts "=" * 80

if all_corrupted.any?
  puts "\n❌ TOTAL: #{all_corrupted.size} registros com encoding corrompido encontrados\n"
  
  # Agrupar por tabela
  by_table = all_corrupted.group_by { |r| r[:table] }
  by_table.each do |table, records|
    puts "\n#{table.upcase}: #{records.size} registros"
    records.first(5).each do |r|
      puts "  • ID #{r[:id]} | #{r[:column]}: #{r[:value]}"
    end
    puts "  ... e mais #{records.size - 5} registros" if records.size > 5
  end
  
  puts "\n💡 Execute o script 'fix_all_encoding.rb' para corrigir estes problemas."
else
  puts "\n✅ Nenhum problema de encoding encontrado no banco de dados!"
end

puts "\n"
