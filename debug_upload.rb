#!/usr/bin/env ruby
# Debug de upload - testar diferentes métodos

require 'aws-sdk-s3'

s3_client = Aws::S3::Client.new(
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  region: ENV['AWS_REGION']
)

bucket = ENV['AWS_BUCKET']

# Pegar um arquivo pequeno
blob = ActiveStorage::Blob.where('byte_size < 100000').where('byte_size > 0').first

if blob
  local_path = Rails.root.join('storage', blob.key[0..1], blob.key[2..3], blob.key)
  
  if File.exist?(local_path)
    puts "Testando upload do arquivo: #{blob.filename}"
    puts "Tamanho no disco: #{File.size(local_path)} bytes"
    puts
    
    # Método 1: Ler tudo na memória
    puts "1. Upload com conteúdo em string..."
    content = File.read(local_path, mode: 'rb')
    puts "  Conteúdo lido: #{content.bytesize} bytes"
    
    s3_client.put_object(
      bucket: bucket,
      key: "test_method1_#{blob.key}",
      body: content,
      content_type: blob.content_type
    )
    
    # Verificar
    obj = s3_client.head_object(bucket: bucket, key: "test_method1_#{blob.key}")
    puts "  Upload concluído: #{obj.content_length} bytes"
    
    if obj.content_length == content.bytesize
      puts "  ✓ SUCESSO!"
    else
      puts "  ✗ FALHOU - tamanhos diferentes!"
    end
    
    # Limpar
    s3_client.delete_object(bucket: bucket, key: "test_method1_#{blob.key}")
    
  else
    puts "Arquivo não existe: #{local_path}"
  end
else
  puts "Nenhum blob encontrado"
end
