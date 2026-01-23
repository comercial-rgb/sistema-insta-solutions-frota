# CORREÇÃO DEFINITIVA DE ENCODING
# O mapeamento correto é:
# - Ü (bytes 195,156) → â (bytes 195,162) 
# - î (bytes 195,174) → Ç (bytes 195,135)
# - Mas já substituímos ambos por ç (195,167)

# Agora precisamos fazer o mapeamento correto baseado no contexto

puts "=" * 80
puts "CORREÇÃO DEFINITIVA - ENCODING"
puts "=" * 80

ActiveRecord::Base.transaction do
  conn = ActiveRecord::Base.connection
  
  # Os caracteres já foram substituídos por ç (195,167)
  # Precisamos analisar palavra por palavra e corrigir
  
  # Lista de palavras conhecidas e suas correções
  corrections = {
    # Palavras com â
    'Mecçnica' => 'Mecânica',
    'Tacçgrafo' => 'Tacógrafo', 
    'tacçgrafo' => 'tacógrafo',
    'Veçculos' => 'Veículos',
    'veçculos' => 'veículos',
    
    # Outras correções comuns
    'Peças' => 'Peças', # já está certo
    'Serviços' => 'Serviços', # já está certo  
    'SERVIçO' => 'SERVIÇO',
  }
  
  puts "\nCorrigindo palavras específicas...\n"
  
  # Corrigir USERS
  corrections.each do |wrong, correct|
    ['name', 'social_name', 'fantasy_name'].each do |col|
      sql = "UPDATE users SET #{col} = REPLACE(#{col}, '#{wrong}', '#{correct}') WHERE #{col} LIKE '%#{wrong}%'"
      result = conn.execute(sql)
      puts "  Users.#{col}: #{wrong} → #{correct}" if result
    end
  end
  
  # Corrigir SERVICES
  corrections.each do |wrong, correct|
    ['name', 'description'].each do |col|
      sql = "UPDATE services SET #{col} = REPLACE(#{col}, '#{wrong}', '#{correct}') WHERE #{col} LIKE '%#{wrong}%'"
      result = conn.execute(sql)
      puts "  Services.#{col}: #{wrong} → #{correct}" if result
    end
  end
  
  puts "\n✓ Correções aplicadas!"
  
  # Verificar resultado
  users_remaining = User.where("name LIKE '%ç%nica%' OR social_name LIKE '%ç%nica%' OR fantasy_name LIKE '%ç%nica%'").count
  puts "\nUsuários com 'ç' onde deveria ser 'â': #{users_remaining}"
end
