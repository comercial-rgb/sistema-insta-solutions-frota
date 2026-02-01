blob = ActiveStorage::Blob.first
if blob
  puts "Blob ID: #{blob.id}"
  puts "Service: #{blob.service_name}"
  puts "Key: #{blob.key}"
  puts "Filename: #{blob.filename}"
  
  # Gerar URL
  url = Rails.application.routes.url_helpers.rails_blob_url(blob, host: "app.frotainstasolutions.com.br")
  puts "\nURL gerada:"
  puts url
  
  # Verificar se arquivo existe no S3
  begin
    exists = blob.service.exist?(blob.key)
    puts "\nArquivo existe no S3: #{exists ? '✓ SIM' : '✗ NÃO'}"
  rescue => e
    puts "\nErro ao verificar S3: #{e.message}"
  end
else
  puts "Nenhum blob encontrado"
end
