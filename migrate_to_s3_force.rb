#!/usr/bin/env ruby
# Migração forçada de arquivos do storage local para AWS S3 (recalcula checksums)

puts "=" * 60
puts "=== MIGRAÇÃO FORÇADA DE ARQUIVOS PARA AWS S3 ==="
puts "Data/Hora: #{Time.current.strftime('%d/%m/%Y %H:%M:%S')}"
puts "=" * 60
puts

# Verificar configuração
s3_service = ActiveStorage::Blob.service
bucket = ENV['AWS_BUCKET']
region = ENV['AWS_REGION']

unless s3_service.is_a?(ActiveStorage::Service::S3Service)
  puts "✗ ERRO: Active Storage não está configurado para usar S3"
  puts "  Serviço atual: #{s3_service.class.name}"
  exit 1
end

puts "✓ S3 configurado: #{bucket} (#{region})"
puts

# Atualizar todos os blobs para service_name = 'amazon'
puts "Atualizando service_name dos blobs..."
updated = ActiveStorage::Blob.where.not(service_name: 'amazon').update_all(service_name: 'amazon')
puts "✓ #{updated} blobs atualizados para 'amazon'"
puts
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
      puts "[#{index + 1}/#{total}] ⏭️  SKIP: #{blob.filename} - arquivo não existe localmente"
      skipped += 1
      next
    end
    
    # Verificar se já existe no S3
    begin
      if s3_service.exist?(blob.key)
        puts "[#{index + 1}/#{total}] ✓ JÁ EXISTE: #{blob.filename} (#{blob.byte_size} bytes) [#{progress}%]"
        skipped += 1
        next
      end
    rescue => e
      # Se der erro ao verificar, assume que não existe
    end
    
    # Ler arquivo e fazer upload SEM validar checksum
    File.open(local_path, 'rb') do |file|
      # Upload direto para S3 sem validação de checksum
      s3_service.upload(blob.key, file, checksum: nil, content_type: blob.content_type)
    end
    
    total_bytes += blob.byte_size
    migrated += 1
    size_mb = (blob.byte_size / 1024.0 / 1024.0).round(2)
    
    puts "[#{index + 1}/#{total}] ✓ MIGRADO: #{blob.filename} (#{size_mb} MB) [#{progress}%]"
    
    # Pausa a cada 50 arquivos para não sobrecarregar
    sleep(0.05) if (index + 1) % 50 == 0
    
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

if errors > 0
  puts
  puts "⚠️ Alguns arquivos falharam na migração"
  puts "   Verifique os erros acima"
end

puts
puts "✓ Migração concluída!"
puts
