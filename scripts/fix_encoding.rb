# Script para corrigir encoding de textos no banco de dados
# Execute: rails runner scripts/fix_encoding.rb

puts "Corrigindo encoding de textos no banco..."

# Mapeamento de correções comuns
corrections = {
  '????' => 'ç',
  '??' => 'ó',
  '??' => 'á',
  '??' => 'é',
  '??' => 'í',
  '??' => 'ã',
  '??' => 'õ',
  '??' => 'ú',
  '??' => 'ê',
  '??' => 'â',
  '??' => 'ô',
  '??' => 'î',
  'Cota????es' => 'Cotações',
  'Diagn??stico' => 'Diagnóstico',
  'Requisi????o' => 'Requisição',
  'od??metro' => 'odômetro',
  'Od??metro' => 'Odômetro',
  'm??o' => 'mão',
  'tra????o' => 'tração',
  '??leo' => 'óleo',
  'sint??tico' => 'sintético',
  'igni????o' => 'ignição',
  'dire????o' => 'direção',
  'c??mbio' => 'câmbio',
  'Lumin??ria' => 'Luminária',
  'L??mpada' => 'Lâmpada',
  'veda????o' => 'vedação',
  'buj??o' => 'bujão',
  'L??quido' => 'Líquido',
  'higieniza????o' => 'higienização',
  'oxi-sanitiza????o' => 'oxi-sanitização',
  'resist??ncia' => 'resistência',
  'diagn??stico' => 'diagnóstico',
  'remo????o' => 'remoção',
  'cabe??ote' => 'cabeçote',
  'inspe????o' => 'inspeção',
  'el??trico' => 'elétrico',
  'pneum??tico' => 'pneumático',
  'mec??nica' => 'mecânica',
  'pe??as' => 'peças',
  'Servi??o' => 'Serviço',
  'Servi??os' => 'Serviços',
  'Aquisi????o' => 'Aquisição',
  'avalia????o' => 'avaliação',
  'aprova????o' => 'aprovação',
  '??leo de motor' => 'óleo de motor'
}

tables_to_fix = [
  { table: 'services', column: 'name' },
  { table: 'order_service_types', column: 'name' },
  { table: 'order_service_proposal_statuses', column: 'name' }
]

total_fixed = 0

tables_to_fix.each do |config|
  table = config[:table]
  column = config[:column]
  
  puts "\nProcessando #{table}.#{column}..."
  
  model_class = table.classify.constantize
  
  model_class.find_each do |record|
    original_value = record.send(column)
    next if original_value.blank?
    
    new_value = original_value.dup
    corrections.each do |wrong, correct|
      new_value.gsub!(wrong, correct)
    end
    
    if new_value != original_value
      record.update_column(column, new_value)
      puts "  ✓ #{record.id}: #{original_value[0..50]} → #{new_value[0..50]}"
      total_fixed += 1
    end
  end
end

puts "\n" + "="*60
puts "Total de registros corrigidos: #{total_fixed}"
puts "="*60
