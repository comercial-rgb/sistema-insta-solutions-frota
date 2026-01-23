# Verificar encoding em clientes e fornecedores

puts "=" * 80
puts "VERIFICAÇÃO DE ENCODING - CLIENTES E FORNECEDORES"
puts "=" * 80

# Verificar USERS (clientes e fornecedores)
puts "\n[USERS - Clientes/Fornecedores]"

patterns = ['%Ü%', '%î%', '%ª%', '%º%']
total_users = 0

patterns.each do |pattern|
  count = User.where("name LIKE ? OR social_name LIKE ? OR fantasy_name LIKE ?", pattern, pattern, pattern).count
  total_users += count
end

if total_users > 0
  puts "Total com problemas: #{total_users}"
  
  User.where("name LIKE '%Ü%' OR social_name LIKE '%Ü%' OR fantasy_name LIKE '%Ü%' OR name LIKE '%î%' OR social_name LIKE '%î%' OR fantasy_name LIKE '%î%'")
    .limit(10)
    .each do |user|
    puts "\nID #{user.id}:"
    puts "  Nome: #{user.name}" if user.name
    puts "  Razão Social: #{user.social_name}" if user.social_name.present?
    puts "  Nome Fantasia: #{user.fantasy_name}" if user.fantasy_name.present?
  end
else
  puts "✓ Nenhum problema encontrado"
end

# Verificar CATEGORIES
puts "\n\n[CATEGORIES]"
cat_problems = Category.where("name LIKE '%Ü%' OR name LIKE '%î%'")

if cat_problems.any?
  puts "Total com problemas: #{cat_problems.count}"
  cat_problems.each do |cat|
    puts "  ID #{cat.id}: #{cat.name}"
  end
else
  puts "✓ Nenhum problema encontrado"
end

# Verificar SERVICES
puts "\n[SERVICES - Peças/Serviços]"
svc_problems = Service.where("name LIKE '%Ü%' OR name LIKE '%î%' OR description LIKE '%Ü%' OR description LIKE '%î%'")

if svc_problems.any?
  puts "Total com problemas: #{svc_problems.count}"
  svc_problems.limit(10).each do |svc|
    puts "  ID #{svc.id}: #{svc.name}"
  end
  
  if svc_problems.count > 10
    puts "  ... e mais #{svc_problems.count - 10} registros"
  end
else
  puts "✓ Nenhum problema encontrado"
end

puts "\n" + "=" * 80
