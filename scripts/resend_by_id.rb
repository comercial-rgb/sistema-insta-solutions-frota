#!/usr/bin/env ruby
# Enviar webhooks das OS que tinham codigo errado na lista
# Uso: RAILS_ENV=production rails runner scripts/resend_by_id.rb

require 'net/http'
require 'json'

WEBHOOK_URL = 'https://portal-finance.onrender.com/api/webhook/frota/receber-os'.freeze
WEBHOOK_TOKEN = '30bfff7ce392036b19d87dd6336c6e326d5312b943e01e3e8926c7aa22136b14'.freeze

# OS encontradas por ID (codigo na lista original estava errado)
# Pulando ID 432 que esta Cancelada
os_ids = [544, 537, 437, 545, 546, 548, 561]

puts "=" * 60
puts "ENVIO DE OS POR ID (codigos corrigidos)"
puts "=" * 60

successes = 0
failures = 0

os_ids.each_with_index do |id, idx|
  os = OrderService.includes(
    :client, :order_service_type, :cost_center, :sub_unit, :vehicle,
    order_service_proposals: [:order_service_proposal_items, :order_service_invoices]
  ).find_by(id: id)

  unless os
    puts "[#{idx+1}/#{os_ids.length}] ID #{id}: NAO ENCONTRADA"
    failures += 1
    next
  end

  status = os.order_service_status&.name || 'desconhecido'
  approved_proposal = os.approved_proposal
  
  unless approved_proposal
    puts "[#{idx+1}/#{os_ids.length}] ID #{id} (#{os.code}, #{status}): SEM PROPOSTA APROVADA"
    failures += 1
    next
  end

  provider = approved_proposal.provider
  provider_name = provider&.fantasy_name.presence || provider&.social_name.presence || 'sem nome'

  service = WebhookFinanceService.new(id)
  begin
    payload = service.send(:payload)
  rescue => e
    puts "[#{idx+1}/#{os_ids.length}] ID #{id} (#{os.code}, #{status}): ERRO PAYLOAD - #{e.message}"
    failures += 1
    next
  end

  begin
    uri = URI(WEBHOOK_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 15
    http.read_timeout = 15

    request = Net::HTTP::Post.new(uri.path, {
      'Content-Type' => 'application/json',
      'X-Webhook-Token' => WEBHOOK_TOKEN
    })
    request.body = payload.to_json

    response = http.request(request)

    if response.code.to_i == 200 || response.code.to_i == 201
      puts "[#{idx+1}/#{os_ids.length}] ID #{id} (#{os.code}, #{status}): OK (HTTP #{response.code}) [#{provider_name}]"
      successes += 1
    else
      body_preview = response.body&.first(200) rescue ''
      puts "[#{idx+1}/#{os_ids.length}] ID #{id} (#{os.code}, #{status}): FALHA HTTP #{response.code} [#{provider_name}] - #{body_preview}"
      failures += 1
    end
  rescue => e
    puts "[#{idx+1}/#{os_ids.length}] ID #{id} (#{os.code}, #{status}): EXCECAO - #{e.message}"
    failures += 1
  end

  sleep 0.5
end

puts
puts "=" * 60
puts "RESULTADO: #{successes} sucesso, #{failures} falhas"
puts "=" * 60
