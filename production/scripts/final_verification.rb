# VERIFICAÇÃO FINAL COMPLETA

puts "=" * 80
puts "VERIFICAÇÃO FINAL - ENCODING"
puts "=" * 80

# Contar todos os problemas restantes
users_u = User.where("name LIKE '%Ü%' OR social_name LIKE '%Ü%' OR fantasy_name LIKE '%Ü%'").count
users_i = User.where("name LIKE '%î%' OR social_name LIKE '%î%' OR fantasy_name LIKE '%î%'").count

cat_u = Category.where("name LIKE '%Ü%'").count
cat_i = Category.where("name LIKE '%î%'").count

svc_u = Service.where("name LIKE '%Ü%'").count
svc_i = Service.where("name LIKE '%î%'").count

puts "\nProblemas com Ü:"
puts "  Users: #{users_u}"
puts "  Categories: #{cat_u}"
puts "  Services: #{svc_u}"
puts "  Total: #{users_u + cat_u + svc_u}"

puts "\nProblemas com î:"
puts "  Users: #{users_i}"
puts "  Categories: #{cat_i}"
puts "  Services: #{svc_i}"
puts "  Total: #{users_i + cat_i + svc_i}"

puts "\n" + "=" * 80
total = users_u + cat_u + svc_u + users_i + cat_i + svc_i
if total == 0
  puts "✅ SUCESSO! Nenhum problema de encoding Ü/î restante!"
else
  puts "⚠️  Ainda há #{total} registros com Ü ou î"
end
puts "=" * 80

# Verificar exemplos dos mais importantes
puts "\nExemplos de CATEGORIES:"
Category.limit(5).each do |c|
  puts "  ID #{c.id}: #{c.name}"
end

puts "\nExemplos de SERVICES (primeiros 10):"
Service.limit(10).each do |s|
  puts "  ID #{s.id}: #{s.name}"
end

puts "\nExemplos de USERS (primeiros 10 com fantasy_name):"
User.where.not(fantasy_name: nil).limit(10).each do |u|
  puts "  ID #{u.id}: #{u.fantasy_name}"
end
