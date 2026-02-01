#!/usr/bin/env ruby
# Migrar APENAS arquivos que TÊM CONTEÚDO para o S3

require 'aws-sdk-s3'

puts "=" * 60
puts "=== MIGRAÇÃO DE ARQUIVOS VÁLIDOS PARA S3 ==="
puts "=" * 60
puts

s3_client = Aws::S3::Client.new(
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  region: ENV['AWS_REGION']
)

bucket = ENV['AWS_BUCKET']
puts "Bucket: #{bucket}"
puts

# Atualizar service_name
ActiveStorage::Blob.update_all(service_name: 'amazon')

blobs = ActiveStorage::Blob.all
total = blobs.count

puts "Processando #{total} blobs..."
puts "-" * 60

migrated = 0
skipped_empty = 0
skipped_exists = 0
errors = 0
total_bytes = 0

blobs.each_with_index do |blob, index|
  progress = ((index + 1).to_f / total * 100).round(1)
  
  begin
    local_path = Rails.root.join('storage', blob.key[0..1], blob.key[2..3], blob.key)
    
    # Pular se não existe
    unless File.exist?(local_path)
      skipped_empty += 1
      next
    end
    
    # Pular se está vazio
    file_size = File.size(local_path)
    if file_size == 0
      skipped_empty += 1
      next
    end
    
    # Verificar se já existe no S3 com tamanho correto
    begin
      obj = s3_client.head_object(bucket: bucket, key: blob.key)
      if obj.content_length == file_size
        skipped_exists += 1
        next
      end
    rescue Aws::S3::Errors::NotFound
      # Não existe, vai fazer upload
    end
    
    # Fazer upload
    content = File.read(local_path, mode: 'rb')
    
    s3_client.put_object(
      bucket: bucket,
      key: blob.key,
      body: content,
      content_type: blob.content_type,
      metadata: {
        'original-filename' => blob.filename.to_s
      }
    )
    
    # Verificar
    obj = s3_client.head_object(bucket: bucket, key: blob.key)
    
    if obj.content_length == file_size
      total_bytes += file_size
      migrated += 1
      size_mb = (file_size / 1024.0 / 1024.0).round(2)
      puts "[#{index + 1}/#{total}] ✓ #{blob.filename} (#{size_mb} MB) [#{progress}%]"
    else
      puts "[#{index + 1}/#{total}] ✗ ERRO: #{blob.filename} - tamanho incorreto!"
      errors += 1
    end
    
    sleep(0.05) if migrated % 50 == 0
    
  rescue => e
    errors += 1
    puts "[#{index + 1}/#{total}] ✗ ERRO: #{blob.filename} - #{e.message}"
  end
end

puts
puts "=" * 60
puts "=== RESUMO ==="
puts "Total verificado: #{total}"
puts "✓ Migrados: #{migrated} (#{(total_bytes / 1024.0 / 1024.0).round(2)} MB)"
puts "⏭️  Já existiam: #{skipped_exists}"
puts "⚠️  Vazios/perdidos: #{skipped_empty}"
puts "✗ Erros: #{errors}"
puts "=" * 60
puts
puts "✓ Migração concluída!"
