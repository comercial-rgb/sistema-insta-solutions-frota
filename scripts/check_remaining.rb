# Verificar padrões restantes após primeira correção

puts "Services com 'Ü' restantes:"
Service.where('name LIKE ?', '%Ü%').limit(15).each do |s|
  puts "  #{s.id}: #{s.name}"
end

puts "\nServices com 'î' restantes:"
Service.where('name LIKE ?', '%î%').limit(15).each do |s|
  puts "  #{s.id}: #{s.name}"
end

puts "\n---\n"

puts "Itens com 'Ü' restantes:"
OrderServiceProposalItem.where('service_name LIKE ?', '%Ü%').limit(15).each do |i|
  puts "  #{i.id}: #{i.service_name}"
end

puts "\nItens com 'î' restantes:"
OrderServiceProposalItem.where('service_name LIKE ?', '%î%').limit(15).each do |i|
  puts "  #{i.id}: #{i.service_name}"
end
