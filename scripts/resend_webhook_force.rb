#!/usr/bin/env ruby
# Script para reenviar webhooks de OS que não foram enviadas ao financeiro
# Ignora a verificação de status (envia mesmo se não estiver em "Autorizada")
# 
# Uso: RAILS_ENV=production rails runner scripts/resend_webhook_force.rb

require 'net/http'
require 'json'

WEBHOOK_URL = 'https://portal-finance.onrender.com/api/webhook/frota/receber-os'.freeze
WEBHOOK_TOKEN = '30bfff7ce392036b19d87dd6336c6e326d5312b943e01e3e8926c7aa22136b14'.freeze

# OS que NÃO apareceram no Financeiro
# Grupo 1: Autorizadas mês 01 (algumas já em Aguardando Pagamento/Paga)
# Grupo 2: Autorizadas mês 02

os_codes = [
  # Grupo 1 - Autorizadas mês 01, não apareceram no financeiro
  'OS4228520251031',
  'OS424142025121',
  'OS424152025121',
  'OS4250720251223',
  'OS4251320251229',
  'OS4253220251230',
  'OS425712026112',
  'OS4250820251226',
  'OS4247820251216',
  'OS4234620251118',
  'OS4254420251230',
  'OS4253720251230',
  'OS4253120251230',
  'OS4251220251229',
  'OS4249120251218',
  'OS4246820251212',
  'OS4246420251212',
  'OS4246520251212',
  # Grupo 2 - Autorizadas mês 02, não apareceram no financeiro
  'OS42152025917',
  'OS4219220251021',
  'OS42432025122',
  'OS4243720251124',
  'OS4248520251217',
  'OS4249420251219',
  'OS4250520251223',
  'OS4251120251229',
  'OS4254520251230',
  'OS4254620251230',
  'OS4254820251230',
  'OS4256120251230',
  'OS425742026112',
  'OS427302026126',
  'OS427482026127',
  'OS427532026128',
  'OS427902026128',
  'OS428272026130',
  'OS420835202622',
  'OS420843202623',
]

puts "=" * 60
puts "REENVIO FORCADO DE WEBHOOKS - OS FALTANTES NO FINANCEIRO"
puts "=" * 60
puts "Total de OS a processar: #{os_codes.length}"
puts

successes = 0
failures = 0
not_found = 0

os_codes.each_with_index do |code, idx|
  os = OrderService.includes(
    :client, :order_service_type, :cost_center, :sub_unit, :vehicle,
    order_service_proposals: [:order_service_proposal_items, :order_service_invoices]
  ).find_by(code: code)
  
  unless os
    puts "[#{idx+1}/#{os_codes.length}] #{code}: NAO ENCONTRADA"
    not_found += 1
    next
  end

  status_name = os.order_service_status&.name || 'desconhecido'
  
  # Busca proposta aprovada
  approved_proposal = os.approved_proposal
  unless approved_proposal
    puts "[#{idx+1}/#{os_codes.length}] #{code} (#{status_name}): SEM PROPOSTA APROVADA - pulando"
    failures += 1
    next
  end

  provider = approved_proposal.provider
  unless provider && (provider.fantasy_name.presence || provider.social_name.presence)
    puts "[#{idx+1}/#{os_codes.length}] #{code} (#{status_name}): FORNECEDOR SEM NOME - pulando"
    failures += 1
    next
  end

  # Monta payload manualmente (bypass do service que verifica status)
  service = WebhookFinanceService.new(os.id)
  payload = service.send(:payload) rescue nil
  
  unless payload
    puts "[#{idx+1}/#{os_codes.length}] #{code} (#{status_name}): ERRO AO MONTAR PAYLOAD - pulando"
    failures += 1
    next
  end

  # Envia manualmente
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
      puts "[#{idx+1}/#{os_codes.length}] #{code} (#{status_name}): OK (HTTP #{response.code})"
      successes += 1
    else
      puts "[#{idx+1}/#{os_codes.length}] #{code} (#{status_name}): FALHA HTTP #{response.code} - #{response.body&.first(200)}"
      failures += 1
    end
  rescue => e
    puts "[#{idx+1}/#{os_codes.length}] #{code} (#{status_name}): EXCECAO - #{e.message}"
    failures += 1
  end

  sleep 0.5 # Pausa entre envios para não sobrecarregar
end

puts
puts "=" * 60
puts "RESULTADO FINAL"
puts "  Enviados com sucesso: #{successes}"
puts "  Falhas:              #{failures}"
puts "  Nao encontradas:     #{not_found}"
puts "  Total processadas:   #{os_codes.length}"
puts "=" * 60
