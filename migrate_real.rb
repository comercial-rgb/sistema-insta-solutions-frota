#!/usr/bin/env ruby
# Migração REAL de arquivos para S3 usando cliente AWS direto

require 'aws-sdk-s3'

puts "=" * 60
puts "=== MIGRAÇÃO REAL PARA AWS S3 ==="
puts "Data/Hora: #{Time.current.strftime('%d/%m/%Y %H:%M:%S')}"
puts "=" * 60
puts

# Configurar cliente S3
s3_client = Aws::S3::Client.new(
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  region: ENV['AWS_REGION']
)

bucket = ENV['AWS_BUCKET']
puts "✓ S3 configurado: #{bucket} (#{ENV['AWS_REGION']})"
puts

# Atualizar service_name
puts "Atualizando service_name dos blobs..."
updated = ActiveStorage::Blob.where.not(service_name: 'amazon').update_all(service_name: 'amazon')
puts "✓ #{updated} blobs atualizados"
puts "-" * 60

# Encontrar todos os blobs
blobs = ActiveStorage::Blob.all
total = blobs.count

puts "Encontrados #{total} arquivos para migrar..."
puts

migrated = 0
skipped = 0
errors = 0
total_bytes = 0

blobs.each_with_index do |blob, index|
  progress = ((index + 1).to_f / total * 100).round(1)
  
  begin
    # Caminho do arquivo local
    local_path = Rails.root.join('storage', blob.key[0..1], blob.key[2..3], blob.key)
    
    # Verificar se o arquivo existe localmente
    unless File.exist?(local_path)
      # puts "[#{index + 1}/#{total}] ⏭️  SKIP: #{blob.filename} - não existe localmente"
      skipped += 1
      next
    end
    
    # Verificar se já existe no S3 (e tem tamanho > 0)
    begin
      obj = s3_client.head_object(bucket: bucket, key: blob.key)
      if obj.content_length > 0
        # puts "[#{index + 1}/#{total}] ✓ JÁ EXISTE: #{blob.filename} (#{(obj.content_length / 1024.0).round(2)} KB) [#{progress}%]"
        skipped += 1
        next
      else
        puts "[#{index + 1}/#{total}] ⚠️  Reupload: #{blob.filename} - arquivo com 0 bytes"
      end
    rescue Aws::S3::Errors::NotFound
      # Arquivo não existe, vai fazer upload
    end
    
    # Fazer upload usando cliente AWS direto
    File.open(local_path, 'rb') do |file|
      s3_client.put_object(
        bucket: bucket,
        key: blob.key,
        body: file,
        content_type: blob.content_type,
        metadata: {
          'filename' => blob.filename.to_s
        }
      )
    end
    
    # Verificar se upload foi bem sucedido
    obj = s3_client.head_object(bucket: bucket, key: blob.key)
    uploaded_size = obj.content_length
    
    if uploaded_size == 0
      puts "[#{index + 1}/#{total}] ✗ ERRO: #{blob.filename} - upload resultou em 0 bytes!"
      errors += 1
    else
      total_bytes += uploaded_size
      migrated += 1
      size_mb = (uploaded_size / 1024.0 / 1024.0).round(2)
      puts "[#{index + 1}/#{total}] ✓ MIGRADO: #{blob.filename} (#{size_mb} MB) [#{progress}%]"
    end
    
    # Pausa a cada 100 arquivos
    sleep(0.1) if (index + 1) % 100 == 0
    
  rescue => e
    errors += 1
    puts "[#{index + 1}/#{total}] ✗ ERRO: #{blob.filename} - #{e.message}"
  end
end

puts
puts "=" * 60
puts "=== RESUMO DA MIGRAÇÃO ==="
puts "Total de arquivos verificados: #{total}"
puts "✓ Migrados: #{migrated}"
puts "⏭️  Já existiam/pulados: #{skipped}"
puts "✗ Erros: #{errors}"
puts "📦 Total migrado: #{(total_bytes / 1024.0 / 1024.0).round(2)} MB"
puts "=" * 60

puts
puts "✓ Migração concluída!"
puts
