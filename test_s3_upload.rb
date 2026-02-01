#!/usr/bin/env ruby
# Teste de upload real para S3

require 'aws-sdk-s3'

s3_client = Aws::S3::Client.new(
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  region: ENV['AWS_REGION']
)

bucket = ENV['AWS_BUCKET']

puts "=" * 60
puts "TESTE DE UPLOAD PARA S3"
puts "=" * 60
puts

# Criar arquivo de teste
test_content = "Este é um teste de upload - #{Time.current}"
test_key = "test_upload_#{Time.now.to_i}.txt"

puts "1. Criando arquivo de teste..."
puts "   Conteúdo: #{test_content}"
puts "   Key: #{test_key}"
puts

puts "2. Fazendo upload..."
begin
  s3_client.put_object(
    bucket: bucket,
    key: test_key,
    body: test_content,
    content_type: 'text/plain'
  )
  puts "✓ Upload concluído!"
rescue => e
  puts "✗ ERRO no upload: #{e.message}"
  puts "   Classe: #{e.class}"
  exit 1
end

puts
puts "3. Verificando arquivo..."
begin
  response = s3_client.get_object(bucket: bucket, key: test_key)
  content = response.body.read
  size = content.bytesize
  
  puts "✓ Arquivo encontrado!"
  puts "   Tamanho: #{size} bytes"
  puts "   Conteúdo: #{content}"
  
  if size == 0
    puts "   ⚠️ ARQUIVO VAZIO!"
  elsif content == test_content
    puts "   ✓ Conteúdo correto!"
  else
    puts "   ✗ Conteúdo diferente!"
  end
rescue => e
  puts "✗ ERRO ao ler: #{e.message}"
end

puts
puts "4. Deletando arquivo de teste..."
begin
  s3_client.delete_object(bucket: bucket, key: test_key)
  puts "✓ Arquivo deletado"
rescue => e
  puts "✗ ERRO ao deletar: #{e.message}"
end

puts
puts "=" * 60
puts "Teste concluído!"
puts "=" * 60
