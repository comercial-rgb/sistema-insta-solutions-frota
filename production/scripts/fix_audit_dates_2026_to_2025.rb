# ================================================================
# Script de Correção: Audits com Data 2026 → 2025
# ================================================================
# Problema: Durante integração do banco, audits foram criados com
# ano 2026 ao invés de 2025 (entre 2026-01-01 e 2026-01-23)
#
# Uso: rails runner scripts/fix_audit_dates_2026_to_2025.rb

puts "=" * 80
puts "CORREÇÃO DE DATAS: Audits 2026 → 2025"
puts "=" * 80
puts

# 1. Identificar audits afetados
puts ">> Identificando audits com data incorreta (2026-01-01 a 2026-01-23)..."
affected_audits = Audited::Audit
  .where("created_at >= ? AND created_at < ?", "2026-01-01", "2026-01-24")
  .order(:created_at)

puts "   Total de audits afetados: #{affected_audits.count}"
puts

if affected_audits.count == 0
  puts "[OK] Nenhum audit com data incorreta encontrado!"
  exit 0
end

# 2. Mostrar estatísticas
puts ">> Estatísticas dos audits afetados:"
puts "-" * 80

by_type = affected_audits.group(:auditable_type).count
by_type.each do |type, count|
  puts "   #{type}: #{count} audits"
end
puts

# Distribuição por data
by_date = affected_audits.group("DATE(created_at)").count.sort_by { |k, v| k }
puts ">> Distribuição por data:"
puts "-" * 80
by_date.each do |date, count|
  puts "   #{date}: #{count} audits"
end
puts

# 3. Mostrar exemplos antes da correção
puts ">> Primeiros 5 exemplos de audits a corrigir:"
puts "-" * 80
affected_audits.limit(5).each do |audit|
  puts "   ID: #{audit.id} | Tipo: #{audit.auditable_type} | Data atual: #{audit.created_at}"
end
puts

# 4. Confirmar correção
print "Deseja prosseguir com a correção? (S/N): "
response = STDIN.gets.chomp.upcase

unless response == 'S'
  puts "\n[!] Operação cancelada pelo usuário"
  exit 0
end

# 5. Executar correção
puts "\n>> Iniciando correção..."
puts "-" * 80

corrected = 0
errors = []

ActiveRecord::Base.transaction do
  affected_audits.find_each do |audit|
    begin
      # Subtrair 1 ano da data
      new_date = audit.created_at - 1.year
      
      # Atualizar sem trigger de callbacks (update_column)
      audit.update_column(:created_at, new_date)
      
      corrected += 1
      
      if corrected % 50 == 0
        print "   Corrigidos: #{corrected}/#{affected_audits.count}\r"
      end
    rescue => e
      errors << { audit_id: audit.id, error: e.message }
    end
  end
end

puts "\n"
puts "=" * 80
puts "RESULTADO DA CORREÇÃO"
puts "=" * 80
puts "   ✓ Audits corrigidos: #{corrected}"
puts "   ✗ Erros: #{errors.count}"
puts

if errors.any?
  puts ">> Erros encontrados:"
  puts "-" * 80
  errors.first(10).each do |error|
    puts "   Audit ID #{error[:audit_id]}: #{error[:error]}"
  end
  puts "   (mostrando primeiros 10 erros)" if errors.count > 10
  puts
end

# 6. Verificação pós-correção
puts ">> Verificação pós-correção:"
puts "-" * 80

remaining = Audited::Audit
  .where("created_at >= ? AND created_at < ?", "2026-01-01", "2026-01-24")
  .count

puts "   Audits ainda com data 2026: #{remaining}"

corrected_audits = Audited::Audit
  .where("created_at >= ? AND created_at < ?", "2025-01-01", "2025-01-24")
  .count

puts "   Audits agora em 2025 (período correspondente): #{corrected_audits}"
puts

if remaining == 0
  puts "[✓] SUCESSO: Todas as datas foram corrigidas!"
else
  puts "[!] ATENÇÃO: Ainda existem #{remaining} audits com data 2026"
end

puts "=" * 80
