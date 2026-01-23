# Verificar problemas de encoding - versão simplificada

puts "=" * 80
puts "VERIFICAÇÃO - COMMITMENTS, COST_CENTERS, CONTRACTS"
puts "=" * 80

# COST CENTERS
puts "\nCOST CENTERS:"
puts "  Total: #{CostCenter.count}"
text_cols = ['name', 'description', 'invoice_name', 'invoice_fantasy_name']
text_cols.each do |col|
  records = CostCenter.where("#{col} LIKE '%ç%'").limit(10)
  if records.any?
    puts "\n  Coluna '#{col}':"
    records.each do |r|
      value = r.send(col)
      puts "    ID #{r.id}: #{value}" if value
    end
  end
end

# CONTRACTS
puts "\n" + "=" * 80
puts "\nCONTRACTS:"
puts "  Total: #{Contract.count}"
contract_cols = Contract.column_names.select { |c| c.include?('name') || c.include?('description') || c.include?('object') }
puts "  Colunas de texto: #{contract_cols.join(', ')}"
contract_cols.each do |col|
  records = Contract.where("#{col} LIKE '%ç%'").limit(10)
  if records.any?
    puts "\n  Coluna '#{col}':"
    records.each do |r|
      value = r.send(col)
      puts "    ID #{r.id}: #{value}" if value
    end
  end
end

# COMMITMENTS
puts "\n" + "=" * 80
puts "\nCOMMITMENTS:"
puts "  Total: #{Commitment.count}"
puts "  Colunas: #{Commitment.column_names.join(', ')}"
# Commitments parece ter poucas colunas de texto
