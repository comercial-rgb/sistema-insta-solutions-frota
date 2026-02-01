#!/usr/bin/env ruby
# Verifica e faz upload de arquivos faltantes no S3

blob = ActiveStorage::Blob.find_by(filename: '1769191524099.jpg')

if blob
  puts "Blob: #{blob.filename} (#{blob.key})"
  
  service = ActiveStorage::Blob.service
  local_path = Rails.root.join('storage', blob.key[0..1], blob.key[2..3], blob.key)
  
  puts "Caminho local: #{local_path}"
  puts "Arquivo existe localmente? #{File.exist?(local_path) ? 'SIM' : 'NÃO'}"
  
  # Tentar fazer upload
  if File.exist?(local_path)
    puts
    puts "Fazendo upload para S3..."
    File.open(local_path, 'rb') do |file|
      service.upload(blob.key, file, checksum: nil, content_type: blob.content_type)
    end
    puts "✓ Upload concluído!"
    
    # Verificar se agora existe
    exists = service.exist?(blob.key)
    puts "Existe no S3 agora? #{exists ? '✓ SIM' : '✗ NÃO'}"
    
    # Tentar gerar URL
    if exists
      url = service.url(blob.key, expires_in: 5.minutes, disposition: "inline", filename: blob.filename, content_type: blob.content_type)
      puts
      puts "URL do S3:"
      puts url
    end
  end
else
  puts "Blob não encontrado!"
end
