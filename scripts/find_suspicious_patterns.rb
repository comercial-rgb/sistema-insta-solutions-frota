# Buscar padrões suspeitos que ainda precisam correção

puts "=" * 80
puts "BUSCA DE PADRÕES SUSPEITOS"
puts "=" * 80

# Padrões que indicam problemas
suspicious_patterns = [
  'çvel',   # deveria ser "óvel" (Automóvel)
  'çrio',   # deveria ser "ório" (Território)
  'çnio',   # deveria ser "ônio" 
  'çdio',   # deveria ser "ódio"
]

puts "\nUSERS com padrões suspeitos:"
suspicious_patterns.each do |pattern|
  users = User.where("name LIKE '%#{pattern}%' OR social_name LIKE '%#{pattern}%' OR fantasy_name LIKE '%#{pattern}%'")
  if users.any?
    puts "\n  Padrão '#{pattern}':"
    users.limit(5).each do |u|
      field = u.fantasy_name if u.fantasy_name&.include?(pattern)
      field ||= u.social_name if u.social_name&.include?(pattern)
      field ||= u.name if u.name&.include?(pattern)
      puts "    ID #{u.id}: #{field}"
    end
  end
end

puts "\nSERVICES com padrões suspeitos:"
suspicious_patterns.each do |pattern|
  svcs = Service.where("name LIKE '%#{pattern}%'")
  if svcs.any?
    puts "\n  Padrão '#{pattern}':"
    svcs.limit(5).each do |s|
      puts "    ID #{s.id}: #{s.name}"
    end
  end
end
