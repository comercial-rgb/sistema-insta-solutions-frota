# Script para reenviar TODAS as OSs autorizadas de Conceição do Castelo ao Portal Financeiro
# Inclui fix de encoding UTF-8/ASCII-8BIT
# Uso: RAILS_ENV=production bundle exec rails runner scripts/retry_webhooks_failed.rb

puts "=" * 70
puts "🔄 REENVIO COMPLETO - OSs Autorizadas → Portal Financeiro"
puts "=" * 70

# Buscar o cliente (Client é alias para User)
client = User.where("fantasy_name LIKE ? OR social_name LIKE ?", "%Concei%Castelo%", "%Concei%Castelo%").first
unless client
  # Tenta busca mais ampla
  client = User.all.find { |u| (u.fantasy_name.to_s + u.social_name.to_s) =~ /concei/i }
end
unless client
  puts "❌ Cliente 'Conceição do Castelo' não encontrado!"
  puts "Listando Users com fantasy_name preenchido:"
  User.where.not(fantasy_name: [nil, '']).limit(20).each { |u| puts "  ID #{u.id}: #{u.fantasy_name}" }
  exit 1
end

puts "📋 Cliente: #{client.fantasy_name || client.social_name} (ID: #{client.id})"

# Buscar TODAS as OSs autorizadas (status 5 ou 7)
autorizada_ids = [
  OrderServiceStatus::AUTORIZADA_ID,
  (OrderServiceStatus::NEW_AUTORIZADA_ID rescue nil)
].compact.uniq

os_list = OrderService.where(client_id: client.id, order_service_status_id: autorizada_ids)
                      .order(:id)

puts "📊 Total de OSs autorizadas: #{os_list.count}"
puts "-" * 70

success_count = 0
error_count = 0
skip_count = 0
errors = []

os_list.each_with_index do |os, idx|
  print "  [#{idx + 1}/#{os_list.count}] OS #{os.code} (ID: #{os.id})... "
  
  begin
    result = WebhookFinanceService.send_authorized_os(os.id)
    
    if result[:success]
      puts "✅ OK"
      success_count += 1
    else
      puts "⚠️  #{result[:error]}"
      skip_count += 1
    end
  rescue => e
    puts "❌ #{e.message}"
    error_count += 1
    errors << { id: os.id, code: os.code, error: e.message }
  end
  
  sleep 0.3  # Delay entre requests
end

puts ""
puts "=" * 70
puts "📊 RESULTADO FINAL:"
puts "   ✅ Enviadas com sucesso: #{success_count}"
puts "   ⚠️  Ignoradas (validação): #{skip_count}"
puts "   ❌ Erros: #{error_count}"
puts "   📋 Total processadas: #{os_list.count}"

if errors.any?
  puts ""
  puts "❌ OSs com erro:"
  errors.each do |e|
    puts "   - OS #{e[:code]} (ID: #{e[:id]}): #{e[:error]}"
  end
end

puts "=" * 70
