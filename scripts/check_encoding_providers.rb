#!/usr/bin/env ruby
# Verifica encoding dos fornecedores problemáticos
# RAILS_ENV=production rails runner scripts/check_encoding_providers.rb

keywords = ['Secret', 'Elot', 'Elet', 'Schio', 'Brilho', 'Bellenz']

puts "=== FORNECEDORES COM POSSÍVEIS PROBLEMAS DE ENCODING ==="
keywords.each do |kw|
  users = User.where("fantasy_name LIKE ? OR social_name LIKE ?", "%#{kw}%", "%#{kw}%")
  users.each do |u|
    hex_fantasy = u.fantasy_name&.bytes&.map { |b| b.to_s(16).rjust(2, '0') }&.join(' ')
    puts "ID: #{u.id} | fantasy: #{u.fantasy_name} | social: #{u.social_name}"
    puts "  HEX fantasy: #{hex_fantasy}"
    puts "  encoding: #{u.fantasy_name&.encoding}"
  end
end

# Buscar TODOS os fornecedores com caracteres problemáticos (mojibake)
puts "\n=== TODOS OS FORNECEDORES COM POSSÍVEL MOJIBAKE ==="
providers = User.where(profile_id: 6) # Perfil fornecedor
count = 0
providers.find_each do |u|
  name = u.fantasy_name.to_s
  # Detectar padrões de mojibake: Ã© (é), Ã£ (ã), Ã§ (ç), Ã³ (ó), Ãª (ê), etc.
  if name.match?(/Ã[£©§³ª¡´]|Ã\p{Lu}/) || name.match?(/[Ã]\s*[©§£³ª]/)
    puts "ID: #{u.id} | #{name}"
    count += 1
  end
end
puts "Total com mojibake: #{count}"
