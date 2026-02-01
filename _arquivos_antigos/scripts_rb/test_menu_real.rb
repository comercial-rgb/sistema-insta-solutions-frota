# Testar o código REAL do menu_helper.rb modificado

puts "=== Testando MENU_ORDER ==="
puts "IDs no MENU_ORDER: #{OrderServiceStatus::MENU_ORDER.inspect}"
puts "Total: #{OrderServiceStatus::MENU_ORDER.size}"

puts "\n=== Testando query modificada ==="
statuses = OrderServiceStatus.where(id: OrderServiceStatus::MENU_ORDER).order(
  Arel.sql("FIELD(id, #{OrderServiceStatus::MENU_ORDER.join(',')})")
)

puts "Total de status retornados: #{statuses.count}"

statuses.each do |s|
  count = OrderService.where(order_service_status_id: s.id).count
  puts "ID #{s.id}: #{s.name} (#{count} OSs)"
end

puts "\n=== Verificando ID 9 especificamente ==="
status_9 = OrderServiceStatus.find_by(id: 9)
if status_9
  puts "ID 9 existe: #{status_9.name}"
  puts "ID 9 está no MENU_ORDER? #{OrderServiceStatus::MENU_ORDER.include?(9)}"
else
  puts "ID 9 NÃO existe no banco"
end
