# Ver registros restantes com problemas

puts "Services com problemas:"
Service.where("name LIKE '%çgrafo%' OR name LIKE '%çtric%'").each do |s|
  puts "  ID #{s.id}: #{s.name}"
end

puts "\nUsers com problemas:"
User.where("fantasy_name LIKE '%çnic%' OR name LIKE '%çnic%'").each do |u|
  puts "  ID #{u.id}: #{u.name} - #{u.fantasy_name}"
end
