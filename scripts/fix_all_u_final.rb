# Correção FINAL de TODOS os padrões Ü restantes

puts "=" * 80
puts "CORREÇÃO FINAL - TODOS OS PADRÕES Ü RESTANTES"
puts "=" * 80

ActiveRecord::Base.transaction do
  conn = ActiveRecord::Base.connection
  
  # TODOS os padrões restantes
  final_fixes = {
    # Câmara
    'CÜmara' => 'Câmara',
    'cÜmara' => 'câmara',
    'CîMARA' => 'CÂMARA',
    
    # Fiscalização
    'FiscalizaÜÜo' => 'Fiscalização',
    'fiscalizaÜÜo' => 'fiscalização',
    'FISCALIZAîO' => 'FISCALIZAÇÃO',
    'FISCALIZAççO' => 'FISCALIZAÇÃO',
    
    # Econômico
    'EconÜmico' => 'Econômico',
    'econÜmico' => 'econômico',
    'ECONÕmico' => 'ECONÔMICO',
    'ECONîMICO' => 'ECONÔMICO',
    
    # Inovação
    'InovaÜÜo' => 'Inovação',
    'inovaÜÜo' => 'inovação',
    'INOVAîO' => 'INOVAÇÃO',
    'INOVAççO' => 'INOVAÇÃO',
    
    # Serviços
    'ServiÜos' => 'Serviços',
    'serviÜos' => 'serviços',
    'SERVIîOS' => 'SERVIÇOS',
    
    # Conceição
    'ConceiÜÜo' => 'Conceição',
    'conceiÜÜo' => 'conceição',
    'CONCEIîO' => 'CONCEIÇÃO',
    'CONCEIççO' => 'CONCEIÇÃO',
    
    # Outros padrões comuns
    'informaÜÜo' => 'informação',
    'InformaÜÜo' => 'Informação',
    'INFORMAîO' => 'INFORMAÇÃO',
    
    'comunicaÜÜo' => 'comunicação',
    'ComunicaÜÜo' => 'Comunicação',
    'COMUNICAîO' => 'COMUNICAÇÃO',
    
    'situaÜÜo' => 'situação',
    'SituaÜÜo' => 'Situação',
    'SITUAîO' => 'SITUAÇÃO',
    
    'funÜÜo' => 'função',
    'FunÜÜo' => 'Função',
    'FUNîO' => 'FUNÇÃO',
    
    'aquisiÜÜo' => 'aquisição',
    'AquisiÜÜo' => 'Aquisição',
    'AQUISIîO' => 'AQUISIÇÃO',
    
    'proteÜÜo' => 'proteção',
    'ProteÜÜo' => 'Proteção',
    'PROTEîO' => 'PROTEÇÃO',
    
    'execuÜÜo' => 'execução',
    'ExecuÜÜo' => 'Execução',
    'EXECUîO' => 'EXECUÇÃO',
    
    'instruÜÜo' => 'instrução',
    'InstruÜÜo' => 'Instrução',
    'INSTRUîO' => 'INSTRUÇÃO',
    
    'manutenÜÜo' => 'manutenção',
    'ManutenÜÜo' => 'Manutenção',
    'MANUTENîO' => 'MANUTENÇÃO',
    
    'alimentaÜÜo' => 'alimentação',
    'AlimentaÜÜo' => 'Alimentação',
    'ALIMENTAîO' => 'ALIMENTAÇÃO',
    
    'habitaÜÜo' => 'habitação',
    'HabitaÜÜo' => 'Habitação',
    'HABITAîO' => 'HABITAÇÃO',
    
    'gestaÜo' => 'gestão',
    'GestaÜo' => 'Gestão',
    'GESTîO' => 'GESTÃO',
    
    'repartiÜÜo' => 'repartição',
    'RepartiÜÜo' => 'Repartição',
    'REPARTIîO' => 'REPARTIÇÃO',
  }
  
  tables = {
    'cost_centers' => nil,  # todas as colunas
    'contracts' => nil,
    'users' => nil,
    'services' => nil,
  }
  
  total = 0
  
  tables.each do |table, _|
    puts "\n#{table.upcase}:"
    
    # Obter colunas de texto
    columns = conn.exec_query("SHOW COLUMNS FROM #{table}").select do |col|
      col['Type'].include?('varchar') || col['Type'].include?('text')
    end.map { |c| c['Field'] }
    
    columns.each do |col|
      final_fixes.each do |wrong, correct|
        result = conn.exec_query("SELECT COUNT(*) as cnt FROM #{table} WHERE #{col} LIKE '%#{wrong}%'")
        count = result.first['cnt']
        
        if count > 0
          conn.execute("UPDATE #{table} SET #{col} = REPLACE(#{col}, '#{wrong}', '#{correct}') WHERE #{col} LIKE '%#{wrong}%'")
          puts "  #{col}: #{wrong} → #{correct} (#{count})"
          total += count
        end
      end
    end
  end
  
  puts "\n" + "=" * 80
  puts "✅ TOTAL FINAL: #{total} correções aplicadas!"
  puts "=" * 80
end

# Verificação final
puts "\nVERIFICAÇÃO FINAL:"
puts "\nCOST CENTERS (primeiros 30):"
CostCenter.where.not(name: nil).limit(30).each do |cc|
  puts "  ID #{cc.id}: #{cc.name}"
end
