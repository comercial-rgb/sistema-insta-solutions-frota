# Verificação detalhada de todos os caracteres problemáticos em Services

puts "=" * 80
puts "VERIFICAÇÃO COMPLETA DE ENCODING - SERVICES"
puts "=" * 80

# Caracteres problemáticos conhecidos
problem_chars = ['Ü', 'î', 'È', 'Ë', 'ç', '?', 'ã', 'õ']

problem_chars.each do |char|
  services = Service.where("name LIKE ?", "%#{char}%")
  
  if services.any?
    puts "\n>>> Serviços com '#{char}' (#{services.count} encontrados):"
    services.limit(30).each do |s|
      puts "  [#{s.id}] #{s.name}"
    end
  end
end

puts "\n" + "=" * 80
puts "VERIFICAÇÃO CONCLUÍDA"
puts "=" * 80
