#!/usr/bin/env ruby
# Script para reenviar webhooks das OS que falharam anteriormente
# - 8 falharam com "provider not found" (nomes já corrigidos)
# - 8 não foram encontradas pelo code (tenta buscar por ID)
#
# Uso: RAILS_ENV=production rails runner scripts/resend_webhook_retry.rb

require 'net/http'
require 'json'

WEBHOOK_URL = 'https://portal-finance.onrender.com/api/webhook/frota/receber-os'.freeze
WEBHOOK_TOKEN = '30bfff7ce392036b19d87dd6336c6e326d5312b943e01e3e8926c7aa22136b14'.freeze

# Todas as 38 OS do envio anterior - reenvia TODAS para garantir
# (as que já estão no financeiro serão atualizadas)
os_codes = [
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

def send_webhook_for_os(os, idx, total)
  provider_name = nil
  approved_proposal = os.approved_proposal
  
  unless approved_proposal
    puts "[#{idx}/#{total}] #{os.code} (ID:#{os.id}): SEM PROPOSTA APROVADA - pulando"
    return :failure
  end

  provider = approved_proposal.provider
  provider_name = provider&.fantasy_name.presence || provider&.social_name.presence
  
  unless provider && provider_name
    puts "[#{idx}/#{total}] #{os.code} (ID:#{os.id}): FORNECEDOR SEM NOME - pulando"
    return :failure
  end

  service = WebhookFinanceService.new(os.id)
  begin
    payload = service.send(:payload)
  rescue => e
    puts "[#{idx}/#{total}] #{os.code} (ID:#{os.id}): ERRO PAYLOAD - #{e.message}"
    return :failure
  end

  unless payload
    puts "[#{idx}/#{total}] #{os.code} (ID:#{os.id}): PAYLOAD NIL - pulando"
    return :failure
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
      puts "[#{idx}/#{total}] #{os.code} (ID:#{os.id}): OK (HTTP #{response.code}) [#{provider_name}]"
      return :success
    else
      body_preview = response.body&.first(200) rescue ''
      puts "[#{idx}/#{total}] #{os.code} (ID:#{os.id}): FALHA HTTP #{response.code} [#{provider_name}] - #{body_preview}"
      return :failure
    end
  rescue => e
    puts "[#{idx}/#{total}] #{os.code} (ID:#{os.id}): EXCECAO - #{e.message}"
    return :failure
  end
end

puts "=" * 60
puts "REENVIO DE WEBHOOKS - RETRY COM NOMES CORRIGIDOS"
puts "=" * 60
puts "Total de codigos a processar: #{os_codes.length}"
puts

successes = 0
failures = 0
not_found = 0

os_codes.each_with_index do |code, idx|
  # Primeiro tenta buscar pelo code exato
  os = OrderService.includes(
    :client, :order_service_type, :cost_center, :sub_unit, :vehicle,
    order_service_proposals: [:order_service_proposal_items, :order_service_invoices]
  ).find_by(code: code)

  # Se não encontrou, tenta extrair o ID do code e buscar por ID
  unless os
    # Formato antigo: OS{client_id}{id}{date} - tentar extrair
    # Formato novo: OS{client_id}-{id}
    if code =~ /^OS(\d+?)(\d{4})\d{6,8}$/
      # Formato antigo: ultimos 6-8 digitos são data, 4 antes disso são o ID
      possible_id = $2.to_i
      os = OrderService.includes(
        :client, :order_service_type, :cost_center, :sub_unit, :vehicle,
        order_service_proposals: [:order_service_proposal_items, :order_service_invoices]
      ).find_by(id: possible_id)
      if os
        puts "  [INFO] Code '#{code}' nao encontrado, mas achou OS por ID #{possible_id} (code atual: #{os.code})"
      end
    end
  end

  unless os
    puts "[#{idx+1}/#{os_codes.length}] #{code}: NAO ENCONTRADA (nem por code, nem por ID)"
    not_found += 1
    next
  end

  result = send_webhook_for_os(os, idx + 1, os_codes.length)
  case result
  when :success then successes += 1
  when :failure then failures += 1
  end

  sleep 0.5
end

puts
puts "=" * 60
puts "RESULTADO FINAL"
puts "  Enviados com sucesso: #{successes}"
puts "  Falhas:              #{failures}"
puts "  Nao encontradas:     #{not_found}"
puts "  Total processadas:   #{os_codes.length}"
puts "=" * 60
