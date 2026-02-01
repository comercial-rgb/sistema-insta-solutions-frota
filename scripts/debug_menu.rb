# Debug - verificar menu
statuses = OrderServiceStatus.menu_ordered.where.not(id: [9, 11])
puts "\n=== Status retornados pelo menu_ordered.where.not(id: [9,11]) ==="
statuses.each do |s|
  count = OrderService.where(order_service_status_id: s.id).count
  puts "ID #{s.id}: #{s.name} (#{count} OSs)"
end

puts "\n=== Verificando ID 9 especificamente ==="
status_9 = OrderServiceStatus.find_by(id: 9)
if status_9
  count_9 = OrderService.where(order_service_status_id: 9).count
  puts "ID 9: #{status_9.name} (#{count_9} OSs)"
end

puts "\n=== MENU_ORDER constante ==="
puts OrderServiceStatus::MENU_ORDER.inspect
