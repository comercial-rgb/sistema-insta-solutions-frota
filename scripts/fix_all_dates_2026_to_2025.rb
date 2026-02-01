# ================================================================
# Script de Correção COMPLETA: Datas 2026 → 2025
# ================================================================
# Problema: Importação do banco com ano incorreto (2026 em vez de 2025)
# Correção: Subtrai 1 ano de TODOS os registros entre 2026-01-01 e 2026-01-23
#
# Uso: rails runner scripts/fix_all_dates_2026_to_2025.rb
#
# ATENÇÃO: Este script modifica múltiplas tabelas. Faça backup antes!
# ================================================================

puts "=" * 80
puts "CORREÇÃO COMPLETA DE DATAS: 2026 → 2025"
puts "=" * 80
puts "Data atual: #{Date.today}"
puts

# Range de datas a corrigir (registros da importação problemática)
START_DATE = "2026-01-01"
END_DATE = "2026-01-24"  # Até 23/01/2026 incluso

puts ">> Analisando registros entre #{START_DATE} e #{END_DATE}..."
puts

# ================================================================
# ESTATÍSTICAS
# ================================================================

stats = {}

# 1. Audits
stats[:audits] = Audited::Audit.where("created_at >= ? AND created_at < ?", START_DATE, END_DATE).count

# 2. OrderServices
stats[:order_services_created] = OrderService.where("created_at >= ? AND created_at < ?", START_DATE, END_DATE).count
stats[:order_services_updated] = OrderService.where("updated_at >= ? AND updated_at < ?", START_DATE, END_DATE).count

# 3. OrderServiceProposals
stats[:proposals_created] = OrderServiceProposal.where("created_at >= ? AND created_at < ?", START_DATE, END_DATE).count
stats[:proposals_updated] = OrderServiceProposal.where("updated_at >= ? AND updated_at < ?", START_DATE, END_DATE).count

# 4. OrderServiceInvoices
stats[:invoices_created] = OrderServiceInvoice.where("created_at >= ? AND created_at < ?", START_DATE, END_DATE).count
stats[:invoices_updated] = OrderServiceInvoice.where("updated_at >= ? AND updated_at < ?", START_DATE, END_DATE).count
stats[:invoices_emission] = OrderServiceInvoice.where("emission_date >= ? AND emission_date < ?", START_DATE, END_DATE).count

# 5. Vehicles
stats[:vehicles] = Vehicle.where("created_at >= ? AND created_at < ?", START_DATE, END_DATE).count

# 6. Users
stats[:users] = User.where("created_at >= ? AND created_at < ?", START_DATE, END_DATE).count

puts ">> ESTATÍSTICAS DE REGISTROS A CORRIGIR:"
puts "-" * 80
puts "   Audits (created_at): #{stats[:audits]}"
puts "   OrderServices (created_at): #{stats[:order_services_created]}"
puts "   OrderServices (updated_at): #{stats[:order_services_updated]}"
puts "   Proposals (created_at): #{stats[:proposals_created]}"
puts "   Proposals (updated_at): #{stats[:proposals_updated]}"
puts "   Invoices (created_at): #{stats[:invoices_created]}"
puts "   Invoices (updated_at): #{stats[:invoices_updated]}"
puts "   Invoices (emission_date): #{stats[:invoices_emission]}"
puts "   Vehicles (created_at): #{stats[:vehicles]}"
puts "   Users (created_at): #{stats[:users]}"
puts

total_operations = stats.values.sum
puts "   TOTAL DE OPERAÇÕES: #{total_operations}"
puts

# ================================================================
# CONFIRMAÇÃO
# ================================================================

puts "=" * 80
puts "⚠️  ATENÇÃO: Esta operação irá modificar #{total_operations} registros!"
puts "=" * 80
puts
print "Deseja continuar? Digite 'SIM' para confirmar: "
response = STDIN.gets.chomp

unless response == 'SIM'
  puts "\n[!] Operação cancelada pelo usuário"
  exit 0
end

# ================================================================
# EXECUÇÃO
# ================================================================

puts "\n>> Iniciando correção..."
puts "=" * 80

results = {
  success: 0,
  errors: []
}

ActiveRecord::Base.transaction do
  begin
    # 1. AUDITS (created_at)
    puts "\n1. Corrigindo Audits..."
    Audited::Audit.where("created_at >= ? AND created_at < ?", START_DATE, END_DATE)
      .find_each do |record|
        record.update_column(:created_at, record.created_at - 1.year)
        results[:success] += 1
        print "   Processados: #{results[:success]}\r" if results[:success] % 100 == 0
      end
    puts "   ✓ Audits corrigidos: #{stats[:audits]}"

    # 2. ORDER SERVICES (created_at e updated_at)
    puts "\n2. Corrigindo OrderServices..."
    OrderService.where("created_at >= ? AND created_at < ?", START_DATE, END_DATE)
      .find_each do |os|
        new_created = os.created_at - 1.year
        new_updated = os.updated_at >= Date.parse(START_DATE) && os.updated_at < Date.parse(END_DATE) ? 
                      os.updated_at - 1.year : os.updated_at
        
        os.update_columns(created_at: new_created, updated_at: new_updated)
        results[:success] += 1
      end
    puts "   ✓ OrderServices corrigidos: #{stats[:order_services_created]}"

    # 3. ORDER SERVICE PROPOSALS (created_at e updated_at)
    puts "\n3. Corrigindo OrderServiceProposals..."
    OrderServiceProposal.where("created_at >= ? AND created_at < ?", START_DATE, END_DATE)
      .find_each do |proposal|
        new_created = proposal.created_at - 1.year
        new_updated = proposal.updated_at >= Date.parse(START_DATE) && proposal.updated_at < Date.parse(END_DATE) ? 
                      proposal.updated_at - 1.year : proposal.updated_at
        
        proposal.update_columns(created_at: new_created, updated_at: new_updated)
        results[:success] += 1
      end
    puts "   ✓ Proposals corrigidos: #{stats[:proposals_created]}"

    # 4. ORDER SERVICE INVOICES (created_at, updated_at, emission_date)
    puts "\n4. Corrigindo OrderServiceInvoices..."
    OrderServiceInvoice.where("created_at >= ? AND created_at < ?", START_DATE, END_DATE)
      .find_each do |invoice|
        new_created = invoice.created_at - 1.year
        new_updated = invoice.updated_at >= Date.parse(START_DATE) && invoice.updated_at < Date.parse(END_DATE) ? 
                      invoice.updated_at - 1.year : invoice.updated_at
        new_emission = invoice.emission_date && invoice.emission_date >= Date.parse(START_DATE) && 
                       invoice.emission_date < Date.parse(END_DATE) ? 
                       invoice.emission_date - 1.year : invoice.emission_date
        
        invoice.update_columns(
          created_at: new_created, 
          updated_at: new_updated,
          emission_date: new_emission
        )
        results[:success] += 1
      end
    puts "   ✓ Invoices corrigidos: #{stats[:invoices_created]}"

    # 5. VEHICLES (created_at)
    puts "\n5. Corrigindo Vehicles..."
    Vehicle.where("created_at >= ? AND created_at < ?", START_DATE, END_DATE)
      .find_each do |vehicle|
        new_created = vehicle.created_at - 1.year
        new_updated = vehicle.updated_at >= Date.parse(START_DATE) && vehicle.updated_at < Date.parse(END_DATE) ? 
                      vehicle.updated_at - 1.year : vehicle.updated_at
        
        vehicle.update_columns(created_at: new_created, updated_at: new_updated)
        results[:success] += 1
      end
    puts "   ✓ Vehicles corrigidos: #{stats[:vehicles]}"

    # 6. USERS (created_at)
    puts "\n6. Corrigindo Users..."
    User.where("created_at >= ? AND created_at < ?", START_DATE, END_DATE)
      .find_each do |user|
        new_created = user.created_at - 1.year
        new_updated = user.updated_at >= Date.parse(START_DATE) && user.updated_at < Date.parse(END_DATE) ? 
                      user.updated_at - 1.year : user.updated_at
        
        user.update_columns(created_at: new_created, updated_at: new_updated)
        results[:success] += 1
      end
    puts "   ✓ Users corrigidos: #{stats[:users]}"

  rescue => e
    results[:errors] << { message: e.message, backtrace: e.backtrace.first(3) }
    raise ActiveRecord::Rollback
  end
end

# ================================================================
# RESULTADO
# ================================================================

puts "\n"
puts "=" * 80
puts "RESULTADO DA CORREÇÃO"
puts "=" * 80
puts "   ✓ Operações bem-sucedidas: #{results[:success]}"
puts "   ✗ Erros: #{results[:errors].count}"
puts

if results[:errors].any?
  puts ">> ERROS ENCONTRADOS:"
  puts "-" * 80
  results[:errors].each do |error|
    puts "   #{error[:message]}"
    error[:backtrace].each { |line| puts "      #{line}" }
  end
  puts
end

# ================================================================
# VERIFICAÇÃO PÓS-CORREÇÃO
# ================================================================

puts ">> VERIFICAÇÃO PÓS-CORREÇÃO:"
puts "-" * 80

remaining_audits = Audited::Audit.where("created_at >= ? AND created_at < ?", START_DATE, END_DATE).count
remaining_os = OrderService.where("created_at >= ? AND created_at < ?", START_DATE, END_DATE).count

puts "   Audits ainda em 2026: #{remaining_audits}"
puts "   OrderServices ainda em 2026: #{remaining_os}"
puts

if remaining_audits == 0 && remaining_os == 0
  puts "[✓] SUCESSO: Todas as datas foram corrigidas!"
else
  puts "[!] ATENÇÃO: Ainda existem registros com data 2026"
end

puts "=" * 80
puts "Correção concluída em #{Time.now}"
puts "=" * 80
