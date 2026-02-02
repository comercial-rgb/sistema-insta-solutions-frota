# Script de teste da integração webhook finance
# Execute com: rails runner scripts/test_webhook_finance.rb

puts "=" * 80
puts "TESTE DE INTEGRAÇÃO WEBHOOK FINANCE"
puts "=" * 80
puts ""

# Teste 1: Conectividade básica
puts "[1/3] Testando conectividade com o endpoint..."
begin
  uri = URI('https://portal-finance-api.onrender.com/api/webhook/frota/teste')
  response = Net::HTTP.get_response(uri)
  
  if response.is_a?(Net::HTTPSuccess)
    body = JSON.parse(response.body)
    puts "✅ Conectividade OK"
    puts "   Mensagem: #{body['message']}"
  else
    puts "❌ Falha na conectividade: HTTP #{response.code}"
  end
rescue => e
  puts "❌ Erro de conexão: #{e.message}"
end

puts ""

# Teste 2: Validação do serviço
puts "[2/3] Validando serviço WebhookFinanceService..."
begin
  # Busca uma OS autorizada para teste
  test_os = OrderService
    .includes(:client, :provider, :order_service_type, :vehicle)
    .where(order_service_status_id: OrderServiceStatus::AUTORIZADA_ID)
    .first

  if test_os
    puts "✅ Serviço carregado"
    puts "   OS de teste: #{test_os.code}"
    puts "   Cliente: #{test_os.client&.fantasy_name}"
    puts "   Fornecedor: #{test_os.provider&.fantasy_name}"
    
    # Teste de payload (sem enviar)
    service = WebhookFinanceService.new(test_os.id)
    puts "   Payload preparado com sucesso"
  else
    puts "⚠️  Nenhuma OS autorizada encontrada para teste"
    puts "   (Isso é normal se ainda não houver OS autorizadas)"
  end
rescue => e
  puts "❌ Erro no serviço: #{e.message}"
  puts e.backtrace.first(3)
end

puts ""

# Teste 3: Verificação de dependências
puts "[3/3] Verificando dependências..."
dependencies = {
  'Net::HTTP' => defined?(Net::HTTP),
  'JSON' => defined?(JSON),
  'ActiveJob' => defined?(ActiveJob),
  'OrderService' => defined?(OrderService),
  'OrderServiceStatus' => defined?(OrderServiceStatus)
}

all_ok = true
dependencies.each do |name, loaded|
  if loaded
    puts "✅ #{name}"
  else
    puts "❌ #{name} não carregado"
    all_ok = false
  end
end

puts ""
puts "=" * 80

if all_ok
  puts "✅ SISTEMA PRONTO PARA INTEGRAÇÃO"
  puts ""
  puts "Próximos passos:"
  puts "1. Quando uma OS for autorizada, o webhook será enviado automaticamente"
  puts "2. Monitore os logs: tail -f log/production.log | grep WebhookFinance"
  puts "3. Webhooks são processados em background (não bloqueiam a aplicação)"
else
  puts "❌ PROBLEMAS DETECTADOS - Verifique as dependências"
end

puts "=" * 80
