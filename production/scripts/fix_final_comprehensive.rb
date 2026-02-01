# CORREÇÃO FINAL - MAPEAMENTO COMPLETO

puts "=" * 80
puts "CORREÇÃO FINAL - TODOS OS PADRÕES"
puts "=" * 80

ActiveRecord::Base.transaction do
  conn = ActiveRecord::Base.connection
  
  # Mapeamento completo: ó → ç erroneamente
  word_fixes = {
    # Palavras completas conhecidas
    'Automçvel' => 'Automóvel',
    'automçvel' => 'automóvel',
    'AUTOMçVEL' => 'AUTOMÓVEL',
    'Automçveis' => 'Automóveis',
    'automçveis' => 'automóveis',
    'AUTOMçVEIS' => 'AUTOMÓVEIS',
    
    # Padrões comuns
    'çleo' => 'óleo',
    'çLEO' => 'ÓLEO',
    'Belçm' => 'Belém',
    'belçm' => 'belém',
    'BELçM' => 'BELÉM',
    'Lçder' => 'Líder',
    'lçder' => 'líder',
    'LçDER' => 'LÍDER',
    'Estçtica' => 'Estética',
    'estçtica' => 'estética',
    'ESTçTICA' => 'ESTÉTICA',
    'Ecolçgica' => 'Ecológica',
    'ecolçgica' => 'ecológica',
    'ECOLçGICA' => 'ECOLÓGICA',
    'Pçblica' => 'Pública',
    'pçblica' => 'pública',
    'PçBLICA' => 'PÚBLICA',
    'Pçblico' => 'Público',
    'pçblico' => 'público',
    'PçBLICO' => 'PÚBLICO',
    'Regiço' => 'Região',
    'regiço' => 'região',
    'REGIçO' => 'REGIÃO',
    'Fundaçço' => 'Fundação',
    'fundaçço' => 'fundação',
    'FUNDAççO' => 'FUNDAÇÃO',
    'Estatçstica' => 'Estatística',
    'estatçstica' => 'estatística',
    'ESTATçSTICA' => 'ESTATÍSTICA',
    'Superintendçncia' => 'Superintendência',
    'superintendçncia' => 'superintendência',
    'SUPERINTENDçNCIA' => 'SUPERINTENDÊNCIA',
    'Diagnçstico' => 'Diagnóstico',
    'diagnçstico' => 'diagnóstico',
    'DIAGNçSTICO' => 'DIAGNÓSTICO',
    'Gçs' => 'Gás',
    'gçs' => 'gás',
    'GçS' => 'GÁS',
    'Saçde' => 'Saúde',
    'saçde' => 'saúde',
    'SAçDE' => 'SAÚDE',
    'Saçda' => 'Saída',
    'saçda' => 'saída',
    'SAçDA' => 'SAÍDA',
    'Fluçdo' => 'Fluído',
    'fluçdo' => 'fluído',
    'FLUçDO' => 'FLUÍDO',
    'Sintçtico' => 'Sintético',
    'sintçtico' => 'sintético',
    'SINTçTICO' => 'SINTÉTICO',
    'Resistçncia' => 'Resistência',
    'resistçncia' => 'resistência',
    'RESISTçNCIA' => 'RESISTÊNCIA',
    'Lçquido' => 'Líquido',
    'lçquido' => 'líquido',
    'LçQUIDO' => 'LÍQUIDO',
    'Mçquina' => 'Máquina',
    'mçquina' => 'máquina',
    'MçQUINA' => 'MÁQUINA',
    'Mçquinas' => 'Máquinas',
    'mçquinas' => 'máquinas',
    'MçQUINAS' => 'MÁQUINAS',
    'Combustçvel' => 'Combustível',
    'combustçvel' => 'combustível',
    'COMBUSTçVEL' => 'COMBUSTÍVEL',
    'Combustçveis' => 'Combustíveis',
    'combustçveis' => 'combustíveis',
    'COMBUSTçVEIS' => 'COMBUSTÍVEIS',
    'Kidço' => 'Kidão',
    'kidço' => 'kidão',
    'KIDçO' => 'KIDÃO',
    'Consçrcio' => 'Consórcio',
    'consçrcio' => 'consórcio',
    'CONSçRCIO' => 'CONSÓRCIO',
    'cçmbio' => 'câmbio',
    'CçMBIO' => 'CÂMBIO',
    'Cçmbio' => 'Câmbio',
    'cçmera' => 'câmera',
    'CçMERA' => 'CÂMERA',
    'Cçmera' => 'Câmera',
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
end
