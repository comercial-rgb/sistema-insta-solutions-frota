# Verificação inteligente - apenas registros COM ERRO real

# Palavras corretas que contêm Ü ou î mas não são erros
correct_patterns = [
  'ELÉTRICO', 'ÓLEO', 'COMBUSTÍVEL', 'DIREÇÃO', 'REVISÃO',
  'ABRAÇADEIRA', 'AÇO', 'PROTETOR', 'AFIXAR', 'MOTOR',
  'AMORTECEDOR', 'DIANTEIRO', 'TRASEIRO', 'CABINE', 'FREIO',
  'SERVIÇO', 'GUINCHO', 'GEOMETRIA', 'PREVENTIVA', 'PNEU'
]

puts "Verificando erros REAIS (excluindo palavras corretas):\n\n"

puts "SERVICES com erro real:"
error_count = 0
Service.where('name LIKE ? OR name LIKE ?', '%Ü%', '%î%').each do |service|
  name = service.name.upcase
  has_error = true
  
  # Se contém apenas padrões corretos, não é erro
  correct_patterns.each do |pattern|
    if name.include?(pattern)
      has_error = false
      break
    end
  end
  
  # Verificar se tem caracteres especiais que indicam erro (ç, ????, etc)
  if name.include?('ç') && !name.include?('Ç') && !name.include?('ÇÃO') && !name.include?('ÇA')
    has_error = true
  end
  
  if has_error && (name.include?('Ü') || name.include?('î'))
    error_count += 1
    puts "  #{service.id}: #{service.name}" if error_count <= 20
  end
end
puts "  Total: #{error_count} services com erro\n\n"

puts "ITEMS com erro real:"
item_error_count = 0
OrderServiceProposalItem.where('service_name LIKE ? OR service_name LIKE ?', '%Ü%', '%î%').each do |item|
  name = item.service_name.upcase
  has_error = true
  
  correct_patterns.each do |pattern|
    if name.include?(pattern)
      has_error = false
      break
    end
  end
  
  if name.include?('ç') && !name.include?('Ç') && !name.include?('ÇÃO') && !name.include?('ÇA')
    has_error = true
  end
  
  if has_error && (name.include?('Ü') || name.include?('î'))
    item_error_count += 1
    puts "  #{item.id}: #{item.service_name}" if item_error_count <= 20
  end
end
puts "  Total: #{item_error_count} items com erro"
