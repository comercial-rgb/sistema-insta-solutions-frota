# Ver bytes de um service específico

service = Service.find(716)
puts "Service ID 716:"
puts "  Name: #{service.name}"
puts "  Bytes: #{service.name.bytes.to_a.join(',')}"
puts

# Ver bytes de users
[6, 15].each do |uid|
  user = User.find(uid)
  if user.fantasy_name
    puts "User ID #{uid}:"
    puts "  Fantasy: #{user.fantasy_name}"
    puts "  Bytes: #{user.fantasy_name.bytes.to_a.join(',')}"
    puts
  end
end

# Ver category
cat = Category.find(2)
puts "Category ID 2:"
puts "  Name: #{cat.name}"
puts "  Bytes: #{cat.name.bytes.to_a.join(',')}"
