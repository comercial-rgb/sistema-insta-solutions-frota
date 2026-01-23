# VERIFICAÇÃO FINAL - BUSCA ABRANGENTE

puts "=" * 80
puts "VERIFICAÇÃO FINAL - TODOS OS PADRÕES SUSPEITOS"
puts "=" * 80

# Lista de todos os padrões suspeitos conhecidos
patterns = [
  'ç',  # ç pode estar em lugares errados
]

# Vou buscar ç seguido de consoante (exceto h), que geralmente indica erro
suspicious_regex = ['çb', 'çc', 'çd', 'çf', 'çg', 'çj', 'çk', 'çl', 'çm', 'çn', 'çp', 'çq', 'çr', 'çs', 'çt', 'çv', 'çw', 'çx', 'çy', 'çz']

puts "\nBuscando padrões suspeitos de ç seguido de consoante..."

total_users = 0
total_services = 0

suspicious_regex.each do |pattern|
  users = User.where("name LIKE '%#{pattern}%' OR social_name LIKE '%#{pattern}%' OR fantasy_name LIKE '%#{pattern}%'")
  services = Service.where("name LIKE '%#{pattern}%' OR description LIKE '%#{pattern}%'")
  
  if users.any? || services.any?
    puts "\nPadrão: '#{pattern}'"
    if users.any?
      puts "  Users: #{users.count}"
      users.limit(3).each do |u|
        text = [u.name, u.social_name, u.fantasy_name].compact.find { |t| t.include?(pattern) }
        puts "    ID #{u.id}: #{text}"
      end
      total_users += users.count
    end
    if services.any?
      puts "  Services: #{services.count}"
      services.limit(3).each do |s|
        puts "    ID #{s.id}: #{s.name}"
      end
      total_services += services.count
    end
  end
end

puts "\n" + "=" * 80
puts "RESUMO:"
puts "  Users com padrões suspeitos: #{total_users}"
puts "  Services com padrões suspeitos: #{total_services}"
puts "  TOTAL: #{total_users + total_services}"
puts "=" * 80

if total_users + total_services == 0
  puts "\n✅ EXCELENTE! Nenhum padrão suspeito encontrado!"
end
