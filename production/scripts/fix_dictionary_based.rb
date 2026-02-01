# CORREÇÃO AUTOMÁTICA BASEADA EM DICIONÁRIO

puts "=" * 80
puts "CORREÇÃO AUTOMÁTICA - PALAVRAS PORTUGUESAS"
puts "=" * 80

ActiveRecord::Base.transaction do
  conn = ActiveRecord::Base.connection
  
  # Dicionário de correções automáticas
  # Substitui padrões conhecidos que foram corrompidos
  word_fixes = {
    # â -> foi corrompido e virou ç
    'Mecçnica' => 'Mecânica',
    'mecçnica' => 'mecânica',
    'Clçnica' => 'Clínica',
    'clçnica' => 'clínica',
    'CLÇNICA' => 'CLÍNICA',
    'Motoclçnica' => 'Motoclínica',
    'motoclçnica' => 'motoclínica',
    'Diagnosticar Clçnica' => 'Diagnosticar Clínica',
    'Tacçgrafo' => 'Tacógrafo',
    'tacçgrafo' => 'tacógrafo',
    'TACÇGRAFO' => 'TACÓGRAFO',
    'TACçGRAFO' => 'TACÓGRAFO',
    'Veçculo' => 'Veículo',
    'veçculo' => 'veículo',
    'VEÇCULO' => 'VEÍCULO',
    'Veçculos' => 'Veículos',
    'veçculos' => 'veículos',
    'VEÇCULOS' => 'VEÍCULOS',
    'Automçvel' => 'Automóvel',
    'automçvel' => 'automóvel',
    'AUTOMçVEL' => 'AUTOMÓVEL',
    'Elçtric' => 'Elétric',
    'elçtric' => 'elétric',
    'ELÇTRIC' => 'ELÉTRIC',
    'ELçTRIC' => 'ELÉTRIC',
    'REVISçO' => 'REVISÃO',
    'Revisço' => 'Revisão',
    'revisço' => 'revisão',
    'Tçcnic' => 'Técnic',
    'tçcnic' => 'técnic',
    'TÇCNIC' => 'TÉCNIC',
    'Acessçrio' => 'Acessório',
    'acessçrio' => 'acessório',
    'ASSESSçRIO' => 'ASSESSÓRIO',
    'Secretçrio' => 'Secretário',
    'secretçrio' => 'secretário',
    'Comçrcio' => 'Comércio',
    'comçrcio' => 'comércio',
    'COMçRCIO' => 'COMÉRCIO',
    'Nçvel' => 'Nível',
    'nçvel' => 'nível',
    'NçVEL' => 'NÍVEL',
    'çgua' => 'água',
    'çGUA' => 'ÁGUA',
    'Primçrio' => 'Primário',
    'primçrio' => 'primário',
    'PRIMçRIO' => 'PRIMÁRIO',
    'Reservatçrio' => 'Reservatório',
    'reservatçrio' => 'reservatório',
    'RESERVATçRIO' => 'RESERVATÓRIO',
    'Expansço' => 'Expansão',
    'expansço' => 'expansão',
    'EXPANSçO' => 'EXPANSÃO',
    'Flexçvel' => 'Flexível',
    'flexçvel' => 'flexível',
    'FLEXçVEL' => 'FLEXÍVEL',
    'Combustçvel' => 'Combustível',
    'combustçvel' => 'combustível',
    'COMBUSTçVEL' => 'COMBUSTÍVEL',
    'Aperfeiçoamento' => 'Aperfeiçoamento', # já está correto
    'Coordenaçço' => 'Coordenação',
    'coordenaçço' => 'coordenação',
    
    # Palavras que já estão corretas (Ç virou ç correto)
    'SERVIçO' => 'SERVIÇO',
    'Serviços' => 'Serviços',
    'serviços' => 'serviços',
    'Peças' => 'Peças',
    'peças' => 'peças',
    'PEÇAS' => 'PEÇAS',
  }
  
  total_fixes = 0
  
  puts "\nCorrigindo USERS..."
  word_fixes.each do |wrong, correct|
    next if wrong == correct
    
    ['name', 'social_name', 'fantasy_name'].each do |col|
      result = conn.exec_query("SELECT COUNT(*) as cnt FROM users WHERE #{col} LIKE '%#{wrong}%'")
      count = result.first['cnt']
      
      if count > 0
        conn.execute("UPDATE users SET #{col} = REPLACE(#{col}, '#{wrong}', '#{correct}') WHERE #{col} LIKE '%#{wrong}%'")
        puts "  #{col}: #{wrong} → #{correct} (#{count} registros)"
        total_fixes += count
      end
    end
  end
  
  puts "\nCorrigindo SERVICES..."
  word_fixes.each do |wrong, correct|
    next if wrong == correct
    
    ['name', 'description'].each do |col|
      result = conn.exec_query("SELECT COUNT(*) as cnt FROM services WHERE #{col} LIKE '%#{wrong}%'")
      count = result.first['cnt']
      
      if count > 0
        conn.execute("UPDATE services SET #{col} = REPLACE(#{col}, '#{wrong}', '#{correct}') WHERE #{col} LIKE '%#{wrong}%'")
        puts "  #{col}: #{wrong} → #{correct} (#{count} registros)"
        total_fixes += count
      end
    end
  end
  
  puts "\n" + "=" * 80
  puts "✓ #{total_fixes} correções aplicadas!"
  puts "=" * 80
  
  # Verificação final
  puts "\nVerificando resultados..."
  
  # Verificar se ainda há problemas conhecidos
  problem_patterns = ['çnic', 'çgrafo', 'çculo', 'çtric']
  remaining = 0
  
  problem_patterns.each do |pattern|
    count = User.where("name LIKE '%#{pattern}%' OR social_name LIKE '%#{pattern}%' OR fantasy_name LIKE '%#{pattern}%'").count
    remaining += count
    puts "  Users com '#{pattern}': #{count}" if count > 0
    
    count = Service.where("name LIKE '%#{pattern}%'").count
    remaining += count
    puts "  Services com '#{pattern}': #{count}" if count > 0
  end
  
  if remaining == 0
    puts "\n✅ Nenhum problema restante detectado!"
  else
    puts "\n⚠️  Ainda há #{remaining} registros com padrões suspeitos"
    
    # Mostrar exemplos
    puts "\nExemplos:"
    User.where("fantasy_name LIKE '%çnic%' OR fantasy_name LIKE '%çgrafo%' OR fantasy_name LIKE '%çculo%'").limit(5).each do |u|
      puts "  User #{u.id}: #{u.fantasy_name}"
    end
  end
end
