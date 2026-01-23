# Corrige encoding em services e order_service_proposal_items

puts "=" * 80
puts "CORRIGINDO ENCODING EM SERVIÇOS E ITENS DE PROPOSTAS"
puts "=" * 80

# Mapeamento de correções
corrections = {
  # Padrões Ü
  'Ü' => 'ê',
  'nÜ' => 'nº',
  'ÜÜ' => 'ção',
  
  # Padrões î  
  'î' => 'ó',
}

# Correções específicas mais complexas
specific_corrections = {
  'ELETRICO' => 'ELÉTRICO',
  'OLEO' => 'ÓLEO',
  'COMBUSTIVEL' => 'COMBUSTÍVEL',
  'EMBREAGEM' => 'EMBREAGEM',
  'FILTROS' => 'FILTROS',
  'CHICOTE' => 'CHICOTE',
  'CILINDRO' => 'CILINDRO',
  'ELETRICO' => 'ELÉTRICO',
  'DIRECAO' => 'DIREÇÃO',
  'ABRACADEIRA' => 'ABRAÇADEIRA',
  'AçO' => 'AÇO',
  'PROTTOR' => 'PROTETOR',
  'AFIRMAR' => 'AFIXAR',
}

total_services = 0
total_items = 0

puts "\n1. CORRIGINDO SERVICES:"
puts "-" * 80

ActiveRecord::Base.transaction do
  # Corrigir Services
  Service.where('name LIKE ? OR name LIKE ?', '%Ü%', '%î%').find_each do |service|
    original = service.name
    fixed = original.dup
    
    # Aplicar correções de padrões
    corrections.each do |pattern, replacement|
      fixed = fixed.gsub(pattern, replacement)
    end
    
    # Aplicar correções específicas
    specific_corrections.each do |wrong, correct|
      fixed = fixed.gsub(/\b#{Regexp.escape(wrong)}\b/, correct)
    end
    
    if fixed != original
      service.update_column(:name, fixed)
      total_services += 1
      puts "   [#{total_services}] ID #{service.id}: #{original} → #{fixed}" if total_services <= 30
    end
  end
  
  puts "   Total: #{total_services} serviços corrigidos"
  
  puts "\n2. CORRIGINDO ORDER_SERVICE_PROPOSAL_ITEMS:"
  puts "-" * 80
  
  # Corrigir OrderServiceProposalItems
  OrderServiceProposalItem.where('service_name LIKE ? OR service_name LIKE ?', '%Ü%', '%î%').find_each do |item|
    original = item.service_name
    fixed = original.dup
    
    # Aplicar correções de padrões
    corrections.each do |pattern, replacement|
      fixed = fixed.gsub(pattern, replacement)
    end
    
    # Aplicar correções específicas
    specific_corrections.each do |wrong, correct|
      fixed = fixed.gsub(/\b#{Regexp.escape(wrong)}\b/, correct)
    end
    
    if fixed != original
      item.update_column(:service_name, fixed)
      total_items += 1
      puts "   [#{total_items}] ID #{item.id}: #{original} → #{fixed}" if total_items <= 30
    end
  end
  
  puts "   Total: #{total_items} itens corrigidos"
end

puts "\n" + "=" * 80
puts "RESUMO:"
puts "  - Services corrigidos: #{total_services}"
puts "  - Itens de propostas corrigidos: #{total_items}"
puts "  - Total: #{total_services + total_items}"
puts "=" * 80
