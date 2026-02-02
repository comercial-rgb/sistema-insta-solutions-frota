os = OrderService.find_by(code: 'OS327772026128')
if os
  puts "ID: #{os.id}"
  puts "Status ID: #{os.order_service_status_id}"
  puts "Cliente: #{os.client.fantasy_name}"
  
  # Tenta enviar webhook manualmente
  puts "\n--- Enviando webhook ---"
  result = WebhookFinanceService.send_authorized_os(os.id)
  puts "Resultado: #{result.inspect}"
else
  puts "OS não encontrada"
end
