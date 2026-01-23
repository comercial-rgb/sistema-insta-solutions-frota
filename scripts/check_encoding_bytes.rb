# Verificar o encoding REAL dos dados (bytes)

puts "Verificando encoding real dos services:\n\n"

# Pegar alguns services para análise
services = Service.limit(20)

services.each do |s|
  name = s.name
  # Verificar encoding
  puts "ID #{s.id}: #{name}"
  puts "  Encoding: #{name.encoding}"
  puts "  Bytes: #{name.bytes.map { |b| b.to_s(16) }.join(' ')}"
  puts "  Válido UTF-8?: #{name.valid_encoding?}"
  puts "---"
end
