#!/usr/bin/env ruby
# Verifica se os arquivos REALMENTE estão no S3

require 'aws-sdk-s3'

# Configurar cliente S3
s3_client = Aws::S3::Client.new(
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  region: ENV['AWS_REGION']
)

bucket = ENV['AWS_BUCKET']

puts "=" * 60
puts "Testando acesso real ao S3"
puts "Bucket: #{bucket}"
puts "Região: #{ENV['AWS_REGION']}"
puts "=" * 60
puts

# Testar listagem do bucket
puts "1. Testando listagem do bucket..."
begin
  response = s3_client.list_objects_v2(bucket: bucket, max_keys: 5)
  puts "✓ Listagem funcionou!"
  puts "  Total de objetos no bucket: #{response.key_count}"
  
  if response.contents.any?
    puts "  Primeiros arquivos:"
    response.contents.each do |obj|
      puts "    - #{obj.key} (#{(obj.size / 1024.0).round(2)} KB)"
    end
  else
    puts "  ⚠️ Bucket está VAZIO!"
  end
rescue => e
  puts "✗ ERRO ao listar: #{e.message}"
  exit 1
end

puts
puts "2. Testando arquivo específico que deu erro..."
blob = ActiveStorage::Blob.find_by(key: 'gt0pzzsum4jf3ttayya3bco45cin')

if blob
  puts "Blob encontrado: #{blob.filename} (ID: #{blob.id})"
  
  # Verificar no disco local
  local_path = Rails.root.join('storage', blob.key[0..1], blob.key[2..3], blob.key)
  puts "Existe no disco local? #{File.exist?(local_path) ? 'SIM' : 'NÃO'}"
  
  if File.exist?(local_path)
    puts "Tamanho no disco: #{(File.size(local_path) / 1024.0).round(2)} KB"
  end
  
  # Verificar no S3
  begin
    s3_client.head_object(bucket: bucket, key: blob.key)
    puts "✓ Existe no S3!"
  rescue Aws::S3::Errors::NotFound
    puts "✗ NÃO existe no S3!"
    
    # Tentar fazer upload agora
    if File.exist?(local_path)
      puts
      puts "Tentando fazer upload..."
      File.open(local_path, 'rb') do |file|
        s3_client.put_object(
          bucket: bucket,
          key: blob.key,
          body: file,
          content_type: blob.content_type
        )
      end
      puts "✓ Upload concluído!"
      
      # Verificar novamente
      s3_client.head_object(bucket: bucket, key: blob.key)
      puts "✓ Confirmado: arquivo agora existe no S3!"
    end
  rescue => e
    puts "✗ ERRO: #{e.message}"
  end
else
  puts "Blob não encontrado no banco!"
end

puts
puts "=" * 60
