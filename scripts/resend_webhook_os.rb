#!/usr/bin/env ruby
# Script para reenviar webhook de OS autorizadas específicas

os_codes = ARGV.any? ? ARGV : ['OS3222025910', 'OS327772026128']

puts "=" * 60
puts "🔄 Reenviando webhooks para OS autorizadas"
puts "=" * 60
puts

os_codes.each do |code|
  os = OrderService.find_by(code: code)
  
  unless os
    puts "❌ #{code}: não encontrada"
    next
  end
  
  unless os.order_service_status_id == OrderServiceStatus::AUTORIZADA_ID
    puts "⚠️  #{code}: não está autorizada (status: #{os.order_service_status&.name})"
    next
  end
  
  puts "📤 #{code}: Enviando webhook..."
  
  begin
    result = WebhookFinanceService.send_authorized_os(os.id)
    
    if result[:success]
      puts "✅ #{code}: Webhook enviado com sucesso!"
      puts "   Resposta: #{result[:response]}"
    else
      puts "❌ #{code}: Falha no webhook"
      puts "   Erro: #{result[:error]}"
    end
  rescue => e
    puts "❌ #{code}: Exceção ao enviar webhook"
    puts "   Erro: #{e.message}"
  end
  
  puts
end

puts "=" * 60
puts "✅ Processamento concluído"
puts "=" * 60
