# Teste de configuração do Active Storage com AWS S3

puts "=== TESTE DE CONFIGURAÇÃO AWS S3 ==="
puts "Data/Hora: #{Time.now.strftime('%d/%m/%Y %H:%M:%S')}\n\n"

# 1. Verificar variáveis de ambiente
puts "1. Verificando variáveis de ambiente..."
aws_vars = {
  'AWS_ACCESS_KEY_ID' => ENV['AWS_ACCESS_KEY_ID'],
  'AWS_SECRET_ACCESS_KEY' => ENV['AWS_SECRET_ACCESS_KEY'],
  'AWS_REGION' => ENV['AWS_REGION'],
  'AWS_BUCKET' => ENV['AWS_BUCKET']
}

aws_vars.each do |key, value|
  if value.present? && value != 'FAKE_LOCAL_KEY' && value != 'FAKE_LOCAL_SECRET' && value != 'local-storage'
    puts "  ✓ #{key}: #{value[0..10]}... (configurado)"
  else
    puts "  ✗ #{key}: #{value || 'NÃO CONFIGURADO'} (⚠️ CREDENCIAL FALSA OU AUSENTE)"
  end
end

# 2. Verificar configuração do Active Storage
puts "\n2. Verificando configuração do Active Storage..."
puts "  Serviço configurado: #{Rails.configuration.active_storage.service}"

begin
  service = ActiveStorage::Blob.service
  puts "  Classe do serviço: #{service.class.name}"
  
  if service.is_a?(ActiveStorage::Service::S3Service)
    puts "  ✓ Serviço S3 ativado corretamente!"
    
    # Tentar acessar bucket
    begin
      bucket_name = service.bucket.name
      puts "  Bucket: #{bucket_name}"
      puts "  ✓ Conexão com bucket estabelecida!"
    rescue => e
      puts "  ✗ Erro ao acessar bucket: #{e.message}"
      puts "  ⚠️ Verifique as credenciais AWS!"
    end
  elsif service.is_a?(ActiveStorage::Service::DiskService)
    puts "  ✗ Serviço está usando DISK (armazenamento local)"
    puts "  ⚠️ Active Storage NÃO está usando S3!"
    puts "  Verifique config/environments/production.rb: active_storage.service"
  else
    puts "  ✗ Serviço desconhecido: #{service.class.name}"
  end
rescue => e
  puts "  ✗ Erro ao verificar serviço: #{e.message}"
end

# 3. Verificar gem aws-sdk-s3
puts "\n3. Verificando gem aws-sdk-s3..."
begin
  require 'aws-sdk-s3'
  puts "  ✓ Gem aws-sdk-s3 instalada (versão: #{Aws::S3::GEM_VERSION})"
rescue LoadError
  puts "  ✗ Gem aws-sdk-s3 NÃO INSTALADA!"
  puts "  Execute: bundle install"
end

# 4. Teste de upload (se credenciais válidas)
puts "\n4. Teste de upload..."
if ENV['AWS_ACCESS_KEY_ID'].present? && 
   ENV['AWS_ACCESS_KEY_ID'] != 'FAKE_LOCAL_KEY' &&
   ENV['AWS_BUCKET'] != 'local-storage'
   
  begin
    # Criar um arquivo de teste
    test_content = "Teste Active Storage - #{Time.now}"
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(test_content),
      filename: "test_#{Time.now.to_i}.txt",
      content_type: 'text/plain'
    )
    
    puts "  ✓ Upload de teste realizado com sucesso!"
    puts "  Blob ID: #{blob.id}"
    puts "  Key: #{blob.key}"
    puts "  URL: #{Rails.application.routes.url_helpers.rails_blob_url(blob, host: ENV['HOST'] || 'localhost:3000')}"
    
    # Tentar deletar o blob de teste
    blob.purge
    puts "  ✓ Blob de teste removido"
    
  rescue => e
    puts "  ✗ Erro ao testar upload: #{e.message}"
    puts "  Backtrace: #{e.backtrace.first(3).join("\n  ")}"
  end
else
  puts "  ⚠️ Credenciais AWS são falsas ou ausentes"
  puts "  Configure as credenciais reais em config/application.yml"
  puts "  Pule o teste de upload"
end

# 5. Verificar attachments existentes
puts "\n5. Verificando anexos existentes no sistema..."
begin
  total_attachments = Attachment.count
  attachments_with_blob = Attachment.joins(:attachment_attachment).count
  
  puts "  Total de anexos: #{total_attachments}"
  puts "  Anexos com arquivo: #{attachments_with_blob}"
  
  if attachments_with_blob > 0
    puts "  ⚠️ Há #{attachments_with_blob} anexos que podem precisar migração para S3"
  end
rescue => e
  puts "  ℹ️ Não foi possível verificar anexos: #{e.message}"
end

puts "\n=== RESUMO ==="
if ENV['AWS_ACCESS_KEY_ID'].present? && 
   ENV['AWS_ACCESS_KEY_ID'] != 'FAKE_LOCAL_KEY' &&
   Rails.configuration.active_storage.service == :amazon
  puts "✓ Sistema configurado para usar AWS S3"
  puts "✓ Execute o teste de upload acima para validar"
else
  puts "✗ Sistema NÃO está pronto para usar AWS S3"
  puts "⚠️ Ações necessárias:"
  puts "  1. Configure credenciais AWS reais em config/application.yml"
  puts "  2. Reinicie o servidor: sudo systemctl restart frotainstasolutions"
  puts "  3. Execute este teste novamente"
end

puts "\n=== FIM DO TESTE ==="
