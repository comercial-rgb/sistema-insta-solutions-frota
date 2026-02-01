#!/usr/bin/env ruby
# Encontrar e migrar os arquivos que estão no disco mas NÃO no S3

require 'aws-sdk-s3'

s3_client = Aws::S3::Client.new(
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  region: ENV['AWS_REGION']
)

bucket = ENV['AWS_BUCKET']

puts "Buscando objetos do S3..."
s3_keys_with_content = {}
continuation_token = nil

loop do
  params = { bucket: bucket, max_keys: 1000 }
  params[:continuation_token] = continuation_token if continuation_token
  
  response = s3_client.list_objects_v2(params)
  response.contents.each do |obj|
    s3_keys_with_content[obj.key] = obj.size if obj.size > 0
  end
  
  break unless response.is_truncated
  continuation_token = response.next_continuation_token
end

puts "✓ #{s3_keys_with_content.count} arquivos com conteúdo no S3"
puts

ActiveStorage::Blob.update_all(service_name: 'amazon')

blobs = ActiveStorage::Blob.all
migrated = 0

puts "Processando blobs..."

blobs.each do |blob|
  local_path = Rails.root.join('storage', blob.key[0..1], blob.key[2..3], blob.key)
  
  next unless File.exist?(local_path)
  
  file_size = File.size(local_path)
  next if file_size == 0
  
  # Verificar se já existe no S3 com conteúdo
  if s3_keys_with_content[blob.key] == file_size
    # Já existe e está correto
    next
  end
  
  # Precisa fazer upload
  begin
    content = File.read(local_path, mode: 'rb')
    
    s3_client.put_object(
      bucket: bucket,
      key: blob.key,
      body: content,
      content_type: blob.content_type
    )
    
    migrated += 1
    puts "[#{migrated}] ✓ #{blob.filename} (#{(file_size / 1024.0).round(2)} KB)"
  rescue => e
    puts "✗ ERRO: #{blob.filename} - #{e.message}"
  end
end

puts
puts "=" * 60
puts "Migrados: #{migrated}"
puts "=" * 60
