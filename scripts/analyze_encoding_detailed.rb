# Análise detalhada dos problemas de encoding

puts "=" * 80
puts "ANÁLISE DETALHADA DE ENCODING"
puts "=" * 80

# Verificar um service específico
service = Service.find(716)
puts "\nService ID 716:"
puts "  Name: #{service.name}"
puts "  Bytes: #{service.name.bytes.inspect}"

# Verificar category
cat = Category.find(2)
puts "\nCategory ID 2:"
puts "  Name: #{cat.name}"
puts "  Bytes: #{cat.name.bytes.inspect}"

# Verificar alguns users
[6, 9, 11].each do |uid|
  user = User.find(uid)
  puts "\nUser ID #{uid}:"
  if user.fantasy_name
    puts "  Fantasy: #{user.fantasy_name}"
    puts "  Bytes: #{user.fantasy_name.bytes.inspect}"
  end
end
