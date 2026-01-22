# Adiciona colunas de recusa de aprovação que faltam no banco de produção
sql = <<-SQL
ALTER TABLE order_service_proposals
ADD COLUMN reason_refused_approval TEXT AFTER pending_manager_authorization,
ADD COLUMN refused_by_manager_id BIGINT AFTER reason_refused_approval,
ADD COLUMN refused_by_manager_at DATETIME AFTER refused_by_manager_id
SQL

begin
  ActiveRecord::Base.connection.execute(sql)
  puts "✅ Colunas adicionadas com sucesso:"
  puts "   - reason_refused_approval (TEXT)"
  puts "   - refused_by_manager_id (BIGINT)"
  puts "   - refused_by_manager_at (DATETIME)"
rescue => e
  if e.message.include?("Duplicate column")
    puts "⚠️  Colunas já existem"
  else
    puts "❌ Erro: #{e.message}"
  end
end

# Verificar
puts "\nColunas de order_service_proposals relacionadas a 'refused':"
OrderServiceProposal.columns.select { |c| c.name.include?('refused') }.each do |col|
  puts "  - #{col.name} (#{col.type})"
end
