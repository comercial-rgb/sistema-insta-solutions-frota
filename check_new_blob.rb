#!/usr/bin/env ruby

# Verificar blob recém-criado
blob = ActiveStorage::Blob.find(1074)

puts "=== BLOB 1074 (Recém-criado) ==="
puts "Key: #{blob.key}"
puts "Size: #{blob.byte_size} bytes"
puts "Service: #{blob.service_name}"
puts "Filename: #{blob.filename}"

# Verificar arquivo local
file_path = Rails.root.join('storage', blob.key[0..1], blob.key[2..3], blob.key)
puts "\n=== ARQUIVO LOCAL ==="
puts "Path: #{file_path}"
puts "Existe localmente? #{File.exist?(file_path)}"
if File.exist?(file_path)
  puts "Tamanho local: #{File.size(file_path)} bytes"
else
  puts "Arquivo NÃO existe localmente - salvo apenas no S3!"
end

# Testar download do S3
puts "\n=== TESTE DE DOWNLOAD DO S3 ==="
begin
  content = blob.download
  puts "✓ Download do S3 bem-sucedido!"
  puts "  Conteúdo baixado: #{content.size} bytes"
  puts "  Preview: #{content[0..50]}"
rescue => e
  puts "✗ Erro ao baixar do S3: #{e.message}"
end
