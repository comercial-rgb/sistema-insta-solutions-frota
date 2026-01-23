# Verificar problemas restantes

puts "Exemplos de USERS com problemas:"
users = User.where("name LIKE '%Ü%' OR social_name LIKE '%Ü%' OR fantasy_name LIKE '%Ü%' OR name LIKE '%î%' OR social_name LIKE '%î%' OR fantasy_name LIKE '%î%'").limit(10)
users.each do |u|
  puts "  ID: #{u.id}"
  puts "    Name: #{u.name}" if u.name&.match?(/[Üî]/)
  puts "    Social: #{u.social_name}" if u.social_name&.match?(/[Üî]/)
  puts "    Fantasy: #{u.fantasy_name}" if u.fantasy_name&.match?(/[Üî]/)
  puts
end

puts "\nExemplos de CATEGORIES com problemas:"
cats = Category.where("name LIKE '%Ü%' OR name LIKE '%î%'").limit(10)
cats.each do |c|
  puts "  ID: #{c.id} - Name: #{c.name}"
end

puts "\nExemplos de SERVICES com problemas:"
svcs = Service.where("name LIKE '%Ü%' OR name LIKE '%î%'").limit(10)
svcs.each do |s|
  puts "  ID: #{s.id} - Name: #{s.name}"
end
