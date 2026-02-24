#!/usr/bin/env ruby
# Script para investigar e corrigir encoding da OS 843
# Uso: RAILS_ENV=production rails runner scripts/fix_os843_encoding.rb

puts "=" * 60
puts "INVESTIGACAO OS 843 - ENCODING"
puts "=" * 60

os = OrderService.find(843)
puts "Code: #{os.code} (enc=#{os.code.to_s.encoding})"
puts "Details encoding: #{os.details.to_s.encoding}"
puts "Details bytes: #{os.details.to_s.bytes.first(50).inspect}"
puts "Details preview: #{os.details.to_s.first(100).inspect}"

# Check all string fields for encoding issues
[:code, :details, :driver, :cancel_justification].each do |field|
  val = os.send(field).to_s
  puts "\n#{field}: enc=#{val.encoding}, valid=#{val.valid_encoding?}, length=#{val.length}"
  unless val.valid_encoding?
    puts "  INVALID ENCODING - forcing UTF-8"
  end
end

ap = os.approved_proposal
if ap
  puts "\nProposal ID: #{ap.id}"
  provider = ap.provider
  if provider
    puts "Provider ID: #{provider.id}"
    puts "Fantasy: #{provider.fantasy_name} (enc=#{provider.fantasy_name.to_s.encoding})"
    puts "Social: #{provider.social_name} (enc=#{provider.social_name.to_s.encoding})"
  end
  
  # Check proposal items for encoding issues
  ap.order_service_proposal_items.each do |item|
    service = item.service
    if service
      name = service.name.to_s
      puts "  Service #{service.id}: #{name.first(50)} (enc=#{name.encoding}, valid=#{name.valid_encoding?})"
      unless name.valid_encoding?
        puts "    >>> ENCODING INVALIDO! Bytes: #{name.bytes.inspect}"
        # Force to UTF-8
        fixed = name.encode('UTF-8', 'ASCII-8BIT', invalid: :replace, undef: :replace, replace: '?')
        puts "    >>> Corrigido: #{fixed}"
        service.update_column(:name, fixed)
        puts "    >>> ATUALIZADO!"
      end
    end
  end
end

# Try to build the payload to find exact error location
puts "\n--- Tentando montar payload ---"
begin
  service = WebhookFinanceService.new(843)
  payload = service.send(:payload)
  puts "Payload montado com sucesso!"
  payload.each do |k, v|
    val = v.to_s
    unless val.valid_encoding?
      puts "  CAMPO #{k}: enc=#{val.encoding}, valid=#{val.valid_encoding?}"
      puts "    Bytes: #{val.bytes.first(20).inspect}"
    end
  end
rescue => e
  puts "ERRO: #{e.class}: #{e.message}"
  puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
end

# Try to fix by converting details field
if os.details.to_s.encoding.to_s == 'ASCII-8BIT' || !os.details.to_s.valid_encoding?
  puts "\n--- Corrigindo campo details ---"
  fixed_details = os.details.to_s.encode('UTF-8', 'ASCII-8BIT', invalid: :replace, undef: :replace, replace: '?')
  os.update_column(:details, fixed_details)
  puts "Details corrigido!"
end

# Retry payload
puts "\n--- Retentando payload apos correcao ---"
begin
  service = WebhookFinanceService.new(843)
  payload = service.send(:payload)
  puts "Payload OK apos correcao!"
  
  # Send webhook
  require 'net/http'
  uri = URI('https://portal-finance.onrender.com/api/webhook/frota/receber-os')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 15
  http.read_timeout = 15

  request = Net::HTTP::Post.new(uri.path, {
    'Content-Type' => 'application/json',
    'X-Webhook-Token' => '30bfff7ce392036b19d87dd6336c6e326d5312b943e01e3e8926c7aa22136b14'
  })
  request.body = payload.to_json

  response = http.request(request)
  puts "Webhook: HTTP #{response.code} - #{response.body.to_s.first(200)}"
rescue => e
  puts "ERRO: #{e.class}: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end
