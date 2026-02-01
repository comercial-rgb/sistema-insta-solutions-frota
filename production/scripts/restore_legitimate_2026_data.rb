# ================================================================
# Script de RESTAURAÇÃO: Dados Legítimos 2025 → 2026
# ================================================================
# Problema: Script anterior corrigiu TODOS os dados 2026→2025,
# mas alguns eram legítimos (criados após 05/01/2026)
#
# Solução: Restaurar dados criados DEPOIS de 05/01/2026 23:59:59
# (data da importação problemática)
#
# Uso: rails runner scripts/restore_legitimate_2026_data.rb
# ================================================================

puts "=" * 80
puts "RESTAURAÇÃO: Dados Legítimos 2025 → 2026"
puts "=" * 80
puts "Data atual: #{Date.today}"
puts

# Data da importação problemática (último registro da importação)
IMPORT_CUTOFF = DateTime.parse("2026-01-05 23:59:59 -0300")
IMPORT_CUTOFF_2025 = IMPORT_CUTOFF - 1.year  # 2025-01-05 23:59:59

puts ">> Critério: Restaurar registros criados DEPOIS de #{IMPORT_CUTOFF}"
puts "   (atualmente em 2025, após #{IMPORT_CUTOFF_2025})"
puts

# ================================================================
# IDENTIFICAR REGISTROS A RESTAURAR
# ================================================================

stats = {}

# 1. OrderServices criadas após a importação
stats[:os_created] = OrderService
  .where("created_at > ?", IMPORT_CUTOFF_2025)
  .where("created_at < ?", Date.today - 1.year + 1.day)
  .count

stats[:os_updated] = OrderService
  .where("updated_at > ?", IMPORT_CUTOFF_2025)
  .where("updated_at < ?", Date.today - 1.year + 1.day)
  .count

# 2. Proposals
stats[:proposals_created] = OrderServiceProposal
  .where("created_at > ?", IMPORT_CUTOFF_2025)
  .where("created_at < ?", Date.today - 1.year + 1.day)
  .count

stats[:proposals_updated] = OrderServiceProposal
  .where("updated_at > ?", IMPORT_CUTOFF_2025)
  .where("updated_at < ?", Date.today - 1.year + 1.day)
  .count

# 3. Invoices
stats[:invoices_created] = OrderServiceInvoice
  .where("created_at > ?", IMPORT_CUTOFF_2025)
  .where("created_at < ?", Date.today - 1.year + 1.day)
  .count

# 4. Vehicles
stats[:vehicles] = Vehicle
  .where("created_at > ?", IMPORT_CUTOFF_2025)
  .where("created_at < ?", Date.today - 1.year + 1.day)
  .count

# 5. Users
stats[:users] = User
  .where("created_at > ?", IMPORT_CUTOFF_2025)
  .where("created_at < ?", Date.today - 1.year + 1.day)
  .count

# 6. Audits
stats[:audits] = Audited::Audit
  .where("created_at > ?", IMPORT_CUTOFF_2025)
  .where("created_at < ?", Date.today - 1.year + 1.day)
  .count

puts ">> ESTATÍSTICAS DE REGISTROS A RESTAURAR:"
puts "-" * 80
puts "   OrderServices (created_at): #{stats[:os_created]}"
puts "   OrderServices (updated_at): #{stats[:os_updated]}"
puts "   Proposals (created_at): #{stats[:proposals_created]}"
puts "   Proposals (updated_at): #{stats[:proposals_updated]}"
puts "   Invoices: #{stats[:invoices_created]}"
puts "   Vehicles: #{stats[:vehicles]}"
puts "   Users: #{stats[:users]}"
puts "   Audits: #{stats[:audits]}"
puts

total = stats.values.sum
puts "   TOTAL DE OPERAÇÕES: #{total}"
puts

if total == 0
  puts "[✓] Nenhum dado legítimo precisa ser restaurado!"
  exit 0
end

# ================================================================
# CONFIRMAÇÃO
# ================================================================

puts "=" * 80
puts "⚠️  Esta operação irá RESTAURAR #{total} registros para 2026"
puts "=" * 80
puts
print "Deseja continuar? Digite 'SIM' para confirmar: "
response = STDIN.gets.chomp

unless response == 'SIM'
  puts "\n[!] Operação cancelada"
  exit 0
end

# ================================================================
# EXECUÇÃO
# ================================================================

puts "\n>> Iniciando restauração..."
puts "=" * 80

restored = 0
errors = []

ActiveRecord::Base.transaction do
  begin
    # 1. AUDITS
    puts "\n1. Restaurando Audits..."
    Audited::Audit
      .where("created_at > ?", IMPORT_CUTOFF_2025)
      .where("created_at < ?", Date.today - 1.year + 1.day)
      .find_each do |audit|
        audit.update_column(:created_at, audit.created_at + 1.year)
        restored += 1
      end
    puts "   ✓ Audits restaurados: #{stats[:audits]}"

    # 2. ORDER SERVICES
    puts "\n2. Restaurando OrderServices..."
    OrderService
      .where("created_at > ?", IMPORT_CUTOFF_2025)
      .where("created_at < ?", Date.today - 1.year + 1.day)
      .find_each do |os|
        new_created = os.created_at + 1.year
        new_updated = os.updated_at > IMPORT_CUTOFF_2025 ? os.updated_at + 1.year : os.updated_at
        
        os.update_columns(created_at: new_created, updated_at: new_updated)
        restored += 1
      end
    puts "   ✓ OrderServices restauradas: #{stats[:os_created]}"

    # 3. PROPOSALS
    puts "\n3. Restaurando Proposals..."
    OrderServiceProposal
      .where("created_at > ?", IMPORT_CUTOFF_2025)
      .where("created_at < ?", Date.today - 1.year + 1.day)
      .find_each do |proposal|
        new_created = proposal.created_at + 1.year
        new_updated = proposal.updated_at > IMPORT_CUTOFF_2025 ? proposal.updated_at + 1.year : proposal.updated_at
        
        proposal.update_columns(created_at: new_created, updated_at: new_updated)
        restored += 1
      end
    puts "   ✓ Proposals restauradas: #{stats[:proposals_created]}"

    # 4. INVOICES
    puts "\n4. Restaurando Invoices..."
    OrderServiceInvoice
      .where("created_at > ?", IMPORT_CUTOFF_2025)
      .where("created_at < ?", Date.today - 1.year + 1.day)
      .find_each do |invoice|
        new_created = invoice.created_at + 1.year
        new_updated = invoice.updated_at > IMPORT_CUTOFF_2025 ? invoice.updated_at + 1.year : invoice.updated_at
        
        invoice.update_columns(created_at: new_created, updated_at: new_updated)
        restored += 1
      end
    puts "   ✓ Invoices restauradas: #{stats[:invoices_created]}"

    # 5. VEHICLES
    puts "\n5. Restaurando Vehicles..."
    Vehicle
      .where("created_at > ?", IMPORT_CUTOFF_2025)
      .where("created_at < ?", Date.today - 1.year + 1.day)
      .find_each do |vehicle|
        new_created = vehicle.created_at + 1.year
        new_updated = vehicle.updated_at > IMPORT_CUTOFF_2025 ? vehicle.updated_at + 1.year : vehicle.updated_at
        
        vehicle.update_columns(created_at: new_created, updated_at: new_updated)
        restored += 1
      end
    puts "   ✓ Vehicles restaurados: #{stats[:vehicles]}"

    # 6. USERS
    puts "\n6. Restaurando Users..."
    User
      .where("created_at > ?", IMPORT_CUTOFF_2025)
      .where("created_at < ?", Date.today - 1.year + 1.day)
      .find_each do |user|
        new_created = user.created_at + 1.year
        new_updated = user.updated_at > IMPORT_CUTOFF_2025 ? user.updated_at + 1.year : user.updated_at
        
        user.update_columns(created_at: new_created, updated_at: new_updated)
        restored += 1
      end
    puts "   ✓ Users restaurados: #{stats[:users]}"

  rescue => e
    errors << { message: e.message, backtrace: e.backtrace.first(3) }
    raise ActiveRecord::Rollback
  end
end

# ================================================================
# RESULTADO
# ================================================================

puts "\n"
puts "=" * 80
puts "RESULTADO DA RESTAURAÇÃO"
puts "=" * 80
puts "   ✓ Registros restaurados: #{restored}"
puts "   ✗ Erros: #{errors.count}"
puts

if errors.any?
  puts ">> ERROS:"
  errors.each { |e| puts "   #{e[:message]}" }
  puts
end

# Verificação
remaining_2025 = OrderService
  .where("created_at > ?", IMPORT_CUTOFF_2025)
  .where("created_at < ?", Date.today - 1.year + 1.day)
  .count

puts ">> VERIFICAÇÃO:"
puts "-" * 80
puts "   OrderServices ainda em 2025 (após cutoff): #{remaining_2025}"
puts

if remaining_2025 == 0
  puts "[✓] SUCESSO: Dados legítimos restaurados para 2026!"
else
  puts "[!] Ainda há #{remaining_2025} registros em 2025"
end

puts "=" * 80
puts "Restauração concluída em #{Time.now}"
puts "=" * 80
