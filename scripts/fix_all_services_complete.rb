# Correção completa de encoding em services e order_service_proposal_items

puts "=" * 80
puts "CORREÇÃO COMPLETA DE ENCODING - SERVIÇOS E ITENS"
puts "=" * 80

def fix_encoding(text)
  return text if text.blank?
  
  fixed = text.dup
  
  # Padrões específicos primeiro (mais específicos para mais genéricos)
  replacements = [
    # Padrões compostos
    ['ÜÜ', 'ção'],
    ['nÜ', 'nº'],
    ['AçO', 'AÇO'],
    
    # Vogais com acento
    ['Ü', 'ê'],
    ['î', 'ó'],
    ['È', 'ã'],
    ['Ë', 'ã'],
    
    # Correções específicas de palavras
    ['ELETRICO', 'ELÉTRICO'],
    ['Eletrico', 'Elétrico'],
    ['eletrico', 'elétrico'],
    ['OLEO', 'ÓLEO'],
    ['Oleo', 'Óleo'],
    ['oleo', 'óleo'],
    ['COMBUSTIVEL', 'COMBUSTÍVEL'],
    ['Combustivel', 'Combustível'],
    ['combustivel', 'combustível'],
    ['DIRECAO', 'DIREÇÃO'],
    ['Direcao', 'Direção'],
    ['direcao', 'direção'],
    ['GEOMETRIA', 'GEOMETRIA'],
    ['Geometria', 'Geometria'],
    ['REVISAO', 'REVISÃO'],
    ['Revisao', 'Revisão'],
    ['revisao', 'revisão'],
    ['PREVENTIVA', 'PREVENTIVA'],
    ['Preventiva', 'Preventiva'],
    ['PROTTOR', 'PROTETOR'],
    ['Prottor', 'Protetor'],
    ['AFIRMAR', 'AFIXAR'],
    ['Afirmar', 'Afixar'],
    ['MOTOR', 'MOTOR'],
    ['Motor', 'Motor'],
    ['motor', 'motor'],
    ['AMORTECEDOR', 'AMORTECEDOR'],
    ['Amortecedor', 'Amortecedor'],
    ['amortecedor', 'amortecedor'],
    ['DIANTEIRO', 'DIANTEIRO'],
    ['Dianteiro', 'Dianteiro'],
    ['dianteiro', 'dianteiro'],
    ['TRASEIRO', 'TRASEIRO'],
    ['Traseiro', 'Traseiro'],
    ['traseiro', 'traseiro'],
    ['CABINE', 'CABINE'],
    ['Cabine', 'Cabine'],
    ['cabine', 'cabine'],
    ['FREIO', 'FREIO'],
    ['Freio', 'Freio'],
    ['freio', 'freio'],
    ['PASTILHAS', 'PASTILHAS'],
    ['Pastilhas', 'Pastilhas'],
    ['EMBREAGEM', 'EMBREAGEM'],
    ['Embreagem', 'Embreagem'],
    ['CILINDRO', 'CILINDRO'],
    ['Cilindro', 'Cilindro'],
    ['MESTRE', 'MESTRE'],
    ['Mestre', 'Mestre'],
    ['CHICOTE', 'CHICOTE'],
    ['Chicote', 'Chicote'],
    ['SERVICO', 'SERVIÇO'],
    ['Servico', 'Serviço'],
    ['servico', 'serviço'],
    ['TERMINAL', 'TERMINAL'],
    ['Terminal', 'Terminal'],
    ['ABRACADEIRA', 'ABRAÇADEIRA'],
    ['Abracadeira', 'Abraçadeira'],
    ['abracadeira', 'abraçadeira'],
    ['GUINCHO', 'GUINCHO'],
    ['Guincho', 'Guincho'],
    ['guincho', 'guincho'],
    ['JUNTA', 'JUNTA'],
    ['Junta', 'Junta'],
    ['junta', 'junta'],
    ['PNEU', 'PNEU'],
    ['Pneu', 'Pneu'],
    ['pneu', 'pneu'],
    ['COLA', 'COLA'],
    ['Cola', 'Cola'],
    ['cola', 'cola'],
    ['FLUIDO', 'FLUIDO'],
    ['Fluido', 'Fluido'],
    ['fluido', 'fluido'],
    ['ANEL', 'ANEL'],
    ['Anel', 'Anel'],
    ['anel', 'anel'],
    ['????o', 'ção'],
    ['????', 'ã'],
    ['??o', 'ão'],
    ['??', 'ó'],
  ]
  
  replacements.each do |pattern, replacement|
    fixed = fixed.gsub(pattern, replacement)
  end
  
  fixed
end

total_services = 0
total_items = 0

puts "\n1. CORRIGINDO SERVICES:"
puts "-" * 80

ActiveRecord::Base.transaction do
  Service.where('name LIKE ? OR name LIKE ? OR name LIKE ?', '%Ü%', '%î%', '%?%').find_each do |service|
    original = service.name
    fixed = fix_encoding(original)
    
    if fixed != original
      service.update_column(:name, fixed)
      total_services += 1
      puts "   [#{total_services}] #{original} → #{fixed}" if total_services <= 50
    end
  end
  
  puts "   ... (mostrando primeiros 50)" if total_services > 50
  puts "   Total: #{total_services} serviços corrigidos"
  
  puts "\n2. CORRIGINDO ORDER_SERVICE_PROPOSAL_ITEMS:"
  puts "-" * 80
  
  OrderServiceProposalItem.where('service_name LIKE ? OR service_name LIKE ? OR service_name LIKE ?', '%Ü%', '%î%', '%?%').find_each do |item|
    original = item.service_name
    fixed = fix_encoding(original)
    
    if fixed != original
      item.update_column(:service_name, fixed)
      total_items += 1
      puts "   [#{total_items}] #{original} → #{fixed}" if total_items <= 50
    end
  end
  
  puts "   ... (mostrando primeiros 50)" if total_items > 50
  puts "   Total: #{total_items} itens corrigidos"
end

puts "\n" + "=" * 80
puts "RESUMO FINAL:"
puts "  - Services corrigidos: #{total_services}"
puts "  - Itens de propostas corrigidos: #{total_items}"
puts "  - TOTAL GERAL: #{total_services + total_items}"
puts "=" * 80
