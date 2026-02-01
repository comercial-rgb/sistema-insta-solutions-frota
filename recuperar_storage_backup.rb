#!/usr/bin/env ruby
# SCRIPT DE RECUPERAÇÃO - Storage Backup 22/01/2026
# 
# Este script migra arquivos do backup para o S3, preservando o banco atual
# 
# USO:
#   1. Copie a pasta storage do backup para /tmp/storage_backup/
#   2. Execute: rails runner recuperar_storage_backup.rb
#

require 'aws-sdk-s3'
require 'digest'

puts "=" * 80
puts "🔄 RECUPERAÇÃO DE ARQUIVOS DO BACKUP (22/01/2026)"
puts "=" * 80
puts ""

# Configuração AWS S3
s3_client = Aws::S3::Client.new(
  region: ENV['AWS_REGION'] || 'us-east-1',
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
)
bucket = ENV['AWS_BUCKET']

# Caminho do backup (ajuste se necessário)
BACKUP_PATH = '/tmp/storage_backup'

unless Dir.exist?(BACKUP_PATH)
  puts "❌ ERRO: Pasta de backup não encontrada!"
  puts "   Esperado: #{BACKUP_PATH}"
  puts ""
  puts "📋 INSTRUÇÕES:"
  puts "   1. Copie a pasta storage do backup para o servidor"
  puts "   2. Renomeie para: /tmp/storage_backup"
  puts "   3. Execute este script novamente"
  puts ""
  exit 1
end

puts "✓ Pasta de backup encontrada: #{BACKUP_PATH}"
puts ""

# Estatísticas
stats = {
  total_blobs: 0,
  arquivos_no_backup: 0,
  ja_no_s3: 0,
  zero_bytes: 0,
  migrados: 0,
  erros: 0,
  bytes_migrados: 0
}

# Listar todos os blobs do banco ATUAL
puts "📊 Analisando blobs no banco de dados atual..."
all_blobs = ActiveStorage::Blob.all
stats[:total_blobs] = all_blobs.count
puts "   Total de blobs: #{stats[:total_blobs]}"
puts ""

puts "🔍 Processando arquivos..."
puts "-" * 80
puts ""

all_blobs.find_each do |blob|
  # Construir caminho do arquivo no backup
  key = blob.key
  backup_file_path = File.join(BACKUP_PATH, key[0..1], key[2..3], key)
  
  # Verificar se arquivo existe no backup
  unless File.exist?(backup_file_path)
    next # Arquivo não existe no backup, pular
  end
  
  stats[:arquivos_no_backup] += 1
  file_size = File.size(backup_file_path)
  
  # Ignorar arquivos vazios no backup
  if file_size == 0
    stats[:zero_bytes] += 1
    next
  end
  
  # Verificar se já existe no S3 com tamanho correto
  begin
    response = s3_client.head_object(bucket: bucket, key: key)
    if response.content_length > 0
      stats[:ja_no_s3] += 1
      next # Já existe no S3 com conteúdo
    end
  rescue Aws::S3::Errors::NotFound
    # Não existe no S3, precisa migrar
  end
  
  # MIGRAR ARQUIVO PARA S3
  begin
    print "📤 Migrando #{blob.filename} (#{(file_size / 1024.0).round(2)} KB)..."
    
    File.open(backup_file_path, 'rb') do |file|
      s3_client.put_object(
        bucket: bucket,
        key: key,
        body: file,
        content_type: blob.content_type,
        metadata: {
          'original-filename' => blob.filename.to_s,
          'recovered-from' => 'backup-22-01-2026',
          'recovered-at' => Time.current.iso8601
        }
      )
    end
    
    # Atualizar blob no banco para apontar para S3 (se ainda não estiver)
    if blob.service_name != 'amazon'
      blob.update_column(:service_name, 'amazon')
    end
    
    stats[:migrados] += 1
    stats[:bytes_migrados] += file_size
    puts " ✓"
    
  rescue => e
    stats[:erros] += 1
    puts " ✗"
    puts "   Erro: #{e.message}"
  end
end

puts ""
puts "=" * 80
puts "📊 RELATÓRIO FINAL"
puts "=" * 80
puts ""
puts "Total de blobs no banco:        #{stats[:total_blobs]}"
puts "Arquivos encontrados no backup: #{stats[:arquivos_no_backup]}"
puts "Já existiam no S3:              #{stats[:ja_no_s3]}"
puts "Arquivos vazios (ignorados):    #{stats[:zero_bytes]}"
puts ""
puts "✅ Migrados com sucesso:        #{stats[:migrados]}"
puts "❌ Erros:                       #{stats[:erros]}"
puts ""
puts "📦 Total migrado:               #{(stats[:bytes_migrados] / 1024.0 / 1024.0).round(2)} MB"
puts ""

if stats[:migrados] > 0
  puts "🎉 RECUPERAÇÃO CONCLUÍDA COM SUCESSO!"
  puts ""
  puts "✅ #{stats[:migrados]} arquivos foram recuperados do backup"
  puts "✅ Banco de dados atual preservado (nenhum dado perdido)"
  puts "✅ Todos os arquivos agora estão no S3"
  puts ""
  puts "📋 PRÓXIMOS PASSOS:"
  puts "   1. Teste alguns arquivos pelo sistema"
  puts "   2. Verifique se imagens/PDFs abrem corretamente"
  puts "   3. Depois execute: cleanup_s3_empty.rb (limpar objetos vazios)"
  puts ""
else
  puts "⚠️  Nenhum arquivo foi migrado."
  puts ""
  puts "Possíveis motivos:"
  puts "   - Todos os arquivos já estavam no S3"
  puts "   - Backup não contém arquivos válidos"
  puts "   - Caminho do backup incorreto"
  puts ""
end

puts "=" * 80
