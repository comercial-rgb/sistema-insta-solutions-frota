#!/usr/bin/env ruby
# Testar se novos uploads estão funcionando

puts "Testando novo upload..."

# Criar um blob de teste
test_file = Tempfile.new(['test', '.txt'])
test_file.write("Teste de upload - #{Time.current}")
test_file.rewind

blob = ActiveStorage::Blob.create_and_upload!(
  io: test_file,
  filename: "test_upload_#{Time.now.to_i}.txt",
  content_type: 'text/plain'
)

puts "✓ Blob criado: ID #{blob.id}"
puts "  Key: #{blob.key}"
puts "  Service: #{blob.service_name}"
puts "  Size: #{blob.byte_size} bytes"

# Verificar se existe
service = ActiveStorage::Blob.service
exists = service.exist?(blob.key)
puts "  Existe no S3? #{exists ? 'SIM' : 'NÃO'}"

# Tentar ler
if exists
  url = service.url(blob.key, expires_in: 5.minutes)
  puts "  URL: #{url[0..100]}..."
  puts "✓ NOVO UPLOAD FUNCIONA!"
else
  puts "✗ UPLOAD FALHOU!"
end

# Limpar
blob.purge
puts "✓ Blob de teste removido"

test_file.close
test_file.unlink
