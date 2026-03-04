#!/usr/bin/env ruby
# ================================================================
# Script para reenviar webhooks de OSs autorizadas para o Portal Financeiro
# Uso: RAILS_ENV=production bundle exec rails runner scripts/resend_webhooks_portal_financeiro.rb
# ================================================================

puts ""
puts "=" * 70
puts "REENVIO DE WEBHOOKS - PORTAL FINANCEIRO"
puts "=" * 70
puts ""

# Buscar cliente "Conceição do Castelo" (busca parcial, case-insensitive)
clients = User.where("LOWER(fantasy_name) LIKE ? OR LOWER(social_name) LIKE ?", 
                      "%conceicao%castelo%", "%conceicao%castelo%")
                .or(User.where("LOWER(fantasy_name) LIKE ? OR LOWER(social_name) LIKE ?", 
                      "%conceição%castelo%", "%conceição%castelo%"))

if clients.empty?
  # Tentar busca mais abrangente
  clients = User.where("fantasy_name LIKE ? OR social_name LIKE ?", "%Castelo%", "%Castelo%")
end

if clients.empty?
  puts "❌ Nenhum cliente encontrado com 'Conceição do Castelo'"
  puts ""
  puts "Clientes disponíveis (primeiros 20):"
  User.where(profile_id: nil).or(User.where.not(profile_id: nil)).limit(20).each do |u|
    puts "  ID #{u.id}: #{u.fantasy_name || u.social_name || u.email}"
  end
  exit 1
end

puts "📋 Clientes encontrados:"
clients.each { |c| puts "  ID #{c.id}: #{c.fantasy_name} (#{c.social_name})" }
puts ""

# Buscar TODAS as OSs autorizadas desses clientes
# Suporta ambos os IDs de status (antigo=5, novo=7)
autorizada_ids = [OrderServiceStatus::AUTORIZADA_ID]
autorizada_ids << OrderServiceStatus::NEW_AUTORIZADA_ID if defined?(OrderServiceStatus::NEW_AUTORIZADA_ID)
autorizada_ids = autorizada_ids.uniq

order_services = OrderService.unscoped
  .where(client_id: clients.pluck(:id))
  .where(order_service_status_id: autorizada_ids)
  .includes(:client, :vehicle, :order_service_type, :cost_center, :provider,
            order_service_proposals: [:order_service_proposal_items, :order_service_invoices])

puts "📊 Total de OSs autorizadas encontradas: #{order_services.count}"
puts ""

if order_services.count == 0
  puts "⚠️  Nenhuma OS no status 'Autorizada' encontrada para este cliente."
  puts ""
  puts "Verificando outros status..."
  all_statuses = OrderService.unscoped
    .where(client_id: clients.pluck(:id))
    .group(:order_service_status_id)
    .count
  all_statuses.each do |status_id, count|
    status = OrderServiceStatus.find_by(id: status_id)
    puts "  Status #{status_id} (#{status&.name || 'Desconhecido'}): #{count} OSs"
  end
  exit 0
end

# Enviar webhooks
success_count = 0
error_count = 0
skipped_count = 0
errors_details = []

order_services.find_each do |os|
  print "  OS #{os.code} (ID: #{os.id})... "
  
  begin
    result = WebhookFinanceService.send_authorized_os(os.id)
    
    if result[:success]
      puts "✅ Enviada com sucesso"
      success_count += 1
    else
      puts "⚠️  #{result[:error]}"
      errors_details << { code: os.code, error: result[:error] }
      error_count += 1
    end
  rescue => e
    puts "❌ Exceção: #{e.message}"
    errors_details << { code: os.code, error: "Exceção: #{e.message}" }
    error_count += 1
  end
  
  # Pequeno delay para não sobrecarregar o portal
  sleep(0.5)
end

puts ""
puts "=" * 70
puts "RESULTADO DO REENVIO"
puts "=" * 70
puts ""
puts "  ✅ Enviadas com sucesso: #{success_count}"
puts "  ⚠️  Com erro: #{error_count}"
puts "  Total processadas: #{success_count + error_count}"
puts ""

if errors_details.any?
  puts "Detalhes dos erros:"
  errors_details.each do |err|
    puts "  - OS #{err[:code]}: #{err[:error]}"
  end
  puts ""
end

puts "Concluído!"
