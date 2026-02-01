#!/usr/bin/env ruby
# Teste de URL de um blob específico

# Pegar o blob que estava dando erro
blob = ActiveStorage::Blob.find_by(filename: '1769191524099.jpg')

if blob
  puts "=" * 60
  puts "Blob encontrado!"
  puts "ID: #{blob.id}"
  puts "Filename: #{blob.filename}"
  puts "Key: #{blob.key}"
  puts "Service Name: #{blob.service_name}"
  puts "Size: #{(blob.byte_size / 1024.0).round(2)} KB"
  puts
  
  # Verificar se existe no S3
  service = ActiveStorage::Blob.service
  exists = service.exist?(blob.key)
  puts "Existe no S3? #{exists ? '✓ SIM' : '✗ NÃO'}"
  puts
  
  # Gerar URL
  url = Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true)
  puts "URL gerada:"
  puts "  #{url}"
  puts
  
  # URL direta do S3
  s3_url = service.url(blob.key, expires_in: 5.minutes, disposition: "inline", filename: blob.filename, content_type: blob.content_type)
  puts "URL direta do S3:"
  puts "  #{s3_url}"
  puts "=" * 60
else
  puts "✗ Blob não encontrado!"
end
