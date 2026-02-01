#!/usr/bin/env ruby
# Migração REAL de arquivos do storage local para AWS S3

puts "=" * 60
puts "=== MIGRAÇÃO DE ARQUIVOS LOCAIS PARA AWS S3 ==="
puts "Data/Hora: #{Time.current.strftime('%d/%m/%Y %H:%M:%S')}"
puts "=" * 60
puts

# Verificar configuração
service = ActiveStorage::Blob.service
bucket = ENV['AWS_BUCKET']
region = ENV['AWS_REGION']

if service.is_a?(ActiveStorage::Service::S3Service)
  puts "✓ Configuração válida detectada"
  puts "  Bucket: #{bucket}"
  puts "  Região: #{region}"
else
  puts "✗ ERRO: Active Storage não está configurado para usar S3"
  puts "  Serviço atual: #{service.class.name}"
  exit 1
end

puts
puts "-" * 60

# Encontrar todos os blobs com service_name 'amazon'
blobs = ActiveStorage::Blob.where(service_name: 'amazon')
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
      if service.exist?(blob.key)
        puts "[#{index + 1}/#{total}] ✓ JÁ EXISTE: #{blob.filename} (#{blob.byte_size} bytes) [#{progress}%]"
        skipped += 1
        next
      end
    rescue => check_error
      # Se falhar ao verificar, vamos tentar fazer upload mesmo assim
    end
    
    # Fazer upload para S3
    File.open(local_path, 'rb') do |file|
      service.upload(blob.key, file, checksum: blob.checksum, content_type: blob.content_type)
    end
    
    total_bytes += blob.byte_size
    migrated += 1
    size_mb = (blob.byte_size / 1024.0 / 1024.0).round(2)
    
    puts "[#{index + 1}/#{total}] ✅ MIGRADO: #{blob.filename} (#{size_mb} MB) [#{progress}%]"
    
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
puts "✅ Migrados: #{migrated}"
puts "⏭️  Já existiam/pulados: #{skipped}"
puts "✗ Erros: #{errors}"
puts "📦 Total migrado: #{(total_bytes / 1024.0 / 1024.0).round(2)} MB"
puts "=" * 60

if errors > 0
  puts
  puts "⚠️ Alguns arquivos falharam na migração"
  puts "   Verifique os erros acima e execute novamente se necessário"
end

puts
puts "✓ Migração concluída!"
puts
