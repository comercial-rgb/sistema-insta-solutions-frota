# Script para investigar dados com ????
puts "Investigando dados com ???? no banco...\n\n"

puts "=== CIDADES COM ? ==="
City.where('name LIKE ?', '%?%').limit(10).each do |c|
  puts "  ID: #{c.id} - Nome: '#{c.name}'"
end

puts "\n=== BANCOS COM ? ==="
Bank.where('name LIKE ?', '%?%').limit(10).each do |b|
  puts "  ID: #{b.id} - Nome: '#{b.name}'"
end

puts "\n=== ENDEREÇOS (BAIRROS) COM ? ==="
Address.where('district LIKE ?', '%?%').limit(10).each do |a|
  puts "  ID: #{a.id} - Bairro: '#{a.district}'"
end

puts "\n=== ORIENTATION MANUALS COM ? ==="
OrientationManual.where('name LIKE ? OR description LIKE ?', '%?%', '%?%').limit(10).each do |m|
  puts "  ID: #{m.id} - Nome: '#{m.name}'"
  puts "  Descrição: '#{m.description[0..50]}...'" if m.description.present?
end
