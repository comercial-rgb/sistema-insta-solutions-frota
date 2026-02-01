# Script para migrar arquivos locais do Active Storage para AWS S3
# Execute APÓS configurar as credenciais AWS reais

puts "=== MIGRAÇÃO DE ARQUIVOS LOCAIS PARA AWS S3 ==="
puts "Data/Hora: #{Time.now.strftime('%d/%m/%Y %H:%M:%S')}"
puts ""

# Verificar se S3 está configurado
unless Rails.configuration.active_storage.service == :amazon
  puts "❌ ERRO: Active Storage não está configurado para usar S3!"
  puts "Verifique config/environments/production.rb"
  exit 1
end

# Verificar credenciais
if ENV['AWS_ACCESS_KEY_ID'] == 'FAKE_LOCAL_KEY' || ENV['AWS_BUCKET'] == 'local-storage'
  puts "❌ ERRO: Credenciais AWS são falsas!"
  puts "Configure credenciais reais em config/application.yml"
  exit 1
end

puts "✓ Configuração válida detectada"
puts "  Bucket: #{ENV['AWS_BUCKET']}"
puts "  Região: #{ENV['AWS_REGION']}"
puts ""

# Localizar serviço disk (local) e S3
local_service = ActiveStorage::Service::DiskService.new(root: Rails.root.join('storage'))
s3_service = ActiveStorage::Blob.service

# Contar blobs
total_blobs = ActiveStorage::Blob.count
puts "Total de blobs no sistema: #{total_blobs}"

if total_blobs == 0
  puts "✓ Nenhum blob para migrar!"
  exit 0
end

puts ""
puts "⚠️ ATENÇÃO: Esta operação vai:"
puts "  1. Fazer upload de #{total_blobs} arquivos para o S3"
puts "  2. Pode levar algum tempo dependendo do tamanho total"
puts "  3. Consumir banda de upload"
puts ""

# Confirmar operação
print "Deseja continuar com a migração? (sim/nao): "
resposta = STDIN.gets.chomp.downcase

unless resposta == 'sim'
  puts "Operação cancelada pelo usuário"
  exit 0
end

puts ""
puts "=== INICIANDO MIGRAÇÃO ==="
puts ""

migrated_count = 0
error_count = 0
skipped_count = 0
total_size = 0

ActiveStorage::Blob.find_each.with_index do |blob, index|
  begin
    print "\rProcessando #{index + 1}/#{total_blobs}: #{blob.filename}..."
    
    # Verificar se já está no S3
    if s3_service.exist?(blob.key)
      skipped_count += 1
      next
    end
    
    # Ler arquivo local
    local_path = local_service.path_for(blob.key)
    
    unless File.exist?(local_path)
      puts "\n  ⚠️ Arquivo local não encontrado: #{blob.filename}"
      error_count += 1
      next
    end
    
    # Fazer upload para S3
    File.open(local_path, 'rb') do |file|
      s3_service.upload(
        blob.key,
        file,
        checksum: blob.checksum,
        content_type: blob.content_type,
        disposition: blob.content_disposition,
        filename: blob.filename
      )
    end
    
    migrated_count += 1
    total_size += blob.byte_size
    
    # Progresso a cada 10 arquivos
    if (index + 1) % 10 == 0
      size_mb = (total_size / 1024.0 / 1024.0).round(2)
      puts "\n  ✓ #{migrated_count} arquivos migrados (#{size_mb} MB)"
    end
    
  rescue => e
    puts "\n  ✗ Erro ao migrar #{blob.filename}: #{e.message}"
    error_count += 1
  end
end

puts "\n"
puts "=== RESUMO DA MIGRAÇÃO ==="
puts "  Total processado: #{total_blobs}"
puts "  ✓ Migrados: #{migrated_count}"
puts "  ⊘ Já existiam no S3: #{skipped_count}"
puts "  ✗ Erros: #{error_count}"
puts "  Tamanho total migrado: #{(total_size / 1024.0 / 1024.0).round(2)} MB"
puts ""

if error_count > 0
  puts "⚠️ Houve #{error_count} erro(s) durante a migração"
  puts "Verifique os logs acima para detalhes"
else
  puts "✓ Migração concluída com sucesso!"
  puts ""
  puts "PRÓXIMOS PASSOS (OPCIONAL):"
  puts "  1. Teste se os arquivos carregam corretamente do S3"
  puts "  2. Após confirmar que tudo funciona, você pode:"
  puts "     rm -rf /var/www/frotainstasolutions/production/storage/*"
  puts "     (para liberar espaço em disco)"
  puts ""
  puts "⚠️ NÃO delete os arquivos locais até confirmar que o S3 está funcionando!"
end

puts ""
puts "=== FIM DA MIGRAÇÃO ==="
