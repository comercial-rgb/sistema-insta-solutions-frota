# Retry only the 4 OSs that failed with encoding error
# Uso: RAILS_ENV=production bundle exec rails runner scripts/retry_4_failed.rb

os_ids = [861, 862, 863, 875]

puts "🔄 Reenviando #{os_ids.length} OSs que falharam com encoding..."
puts "-" * 50

os_ids.each do |os_id|
  os = OrderService.find_by(id: os_id)
  print "  OS #{os&.code} (ID: #{os_id})... "
  
  begin
    result = WebhookFinanceService.send_authorized_os(os_id)
    if result[:success]
      puts "✅ OK"
    else
      puts "⚠️ #{result[:error]}"
    end
  rescue => e
    puts "❌ #{e.class}: #{e.message}"
  end
  
  sleep 0.5
end

puts "-" * 50
puts "Concluído!"
