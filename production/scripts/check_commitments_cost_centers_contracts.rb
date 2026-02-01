# Verificar problemas de encoding em Empenhos, Centros de Custo e Contratos

puts "=" * 80
puts "VERIFICAÇÃO - COMMITMENTS, COST_CENTERS, CONTRACTS"
puts "=" * 80

# Verificar se as tabelas existem
tables = {
  'Commitments' => Commitment,
  'CostCenters' => CostCenter,
  'Contracts' => Contract
}

tables.each do |name, model|
  puts "\n#{name}:"
  puts "  Colunas: #{model.column_names.join(', ')}"
  puts "  Total de registros: #{model.count}"
  
  # Buscar padrões suspeitos nas colunas de texto
  text_columns = model.columns.select { |c| c.type == :string || c.type == :text }.map(&:name)
  
  text_columns.each do |col|
    # Buscar ç seguido de vogais que podem indicar erro (ço, çu, çv, etc)
    suspicious = model.where("#{col} LIKE '%ç%'").limit(10)
    if suspicious.any?
      puts "\n  Coluna '#{col}' com ç:"
      suspicious.each do |record|
        value = record.send(col)
        if value&.include?('ç')
          puts "    ID #{record.id}: #{value}"
        end
      end
    end
  end
end
