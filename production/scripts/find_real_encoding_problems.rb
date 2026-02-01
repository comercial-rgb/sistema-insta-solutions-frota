# Buscar services com encoding realmente incorreto

puts "Buscando services com problemas REAIS de encoding:\n\n"

# Bytes incorretos conhecidos
wrong_bytes = {
  'c3 9c' => 'Ü',  # Este é ERRADO (deveria ser ê ou outro)
  'c3 ae' => 'î',  # Este é ERRADO
}

problem_count = 0

Service.find_each do |s|
  name = s.name
  hex = name.bytes.map { |b| b.to_s(16).rjust(2, '0') }.join(' ')
  
  # Verificar se tem os bytes problemáticos
  if hex.include?('c3 9c') || hex.include?('c3 ae')
    problem_count += 1
    puts "[#{problem_count}] ID #{s.id}: #{name}"
    puts "  Bytes: #{hex}"
    puts "---"
    
    break if problem_count >= 30
  end
end

puts "\nTotal de problemas encontrados: #{problem_count}"

if problem_count == 0
  puts "\n✅ ÓTIMA NOTÍCIA: Não há problemas de encoding nos Services!"
  puts "Os dados estão salvos corretamente em UTF-8."
end
