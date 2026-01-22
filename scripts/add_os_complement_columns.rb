# Adiciona colunas is_complement e parent_proposal_id em order_services

puts "Adicionando colunas faltantes em order_services..."

ActiveRecord::Base.connection.execute("
  ALTER TABLE order_services
  ADD COLUMN is_complement BOOLEAN DEFAULT FALSE AFTER order_service_status_id,
  ADD COLUMN parent_proposal_id BIGINT AFTER is_complement
")

puts "✅ Colunas adicionadas com sucesso!"
puts "   - is_complement (BOOLEAN, default: FALSE)"
puts "   - parent_proposal_id (BIGINT)"

# Verificar
puts "\nVerificando..."
cols = ActiveRecord::Base.connection.columns('order_services')
  .select { |c| ['is_complement', 'parent_proposal_id'].include?(c.name) }

cols.each do |col|
  puts "  ✅ #{col.name} (#{col.type})"
end
