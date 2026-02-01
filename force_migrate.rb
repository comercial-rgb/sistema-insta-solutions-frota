#!/usr/bin/env ruby
# Migrar arquivos que FALTAM no S3

require 'aws-sdk-s3'

puts "=" * 60
puts "=== MIGRAÇÃO FORÇADA PARA S3 ==="
puts "=" * 60
puts

s3_client = Aws::S3::Client.new(
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  region: ENV['AWS_REGION']
)

bucket = ENV['AWS_BUCKET']

# Atualizar service_name
ActiveStorage::Blob.update_all(service_name: 'amazon')

blobs = ActiveStorage::Blob.all
migrated = 0
skipped = 0

blobs.each_with_index do |blob, index|
  begin
    local_path = Rails.root.join('storage', blob.key[0..1], blob.key[2..3], blob.key)
    
    next unless File.exist?(local_path)
    
    file_size = File.size(local_path)
    next if file_size == 0
    
    # Verificar no S3
    begin
      obj = s3_client.head_object(bucket: bucket, key: blob.key)
      # Se já existe e tem tamanho correto, pula
      if obj.content_length == file_size
        skipped += 1
        next
      end
    rescue Aws::S3::Errors::NotFound
      # Não existe, precisa fazer upload
    end
    
    # Upload
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
puts "Migrados: #{migrated}"
puts "Já existiam: #{skipped}"
