# Verificar usuários com encoding corrompido

puts "=" * 60
puts "USUÁRIOS COM PROBLEMAS DE ENCODING (????)"
puts "=" * 60

users = User.where("name LIKE '%??%'")

if users.any?
  puts "\nTotal encontrado: #{users.count} usuários\n"
  
  users.limit(20).each do |user|
    puts "ID #{user.id}: #{user.name}"
  end
  
  if users.count > 20
    puts "\n... e mais #{users.count - 20} usuários"
  end
else
  puts "\n✓ Nenhum usuário com problema de encoding encontrado!"
end

puts "\n" + "=" * 60
