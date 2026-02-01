# Script para criar placeholders de imagens faltantes
# Execute: rails runner scripts/create_image_placeholders.rb

puts "Criando placeholders para imagens faltantes..."

ActiveStorage::Blob.find_each do |blob|
  # Caminho onde o arquivo deveria estar
  folder = blob.key[0..1]
  subfolder = blob.key[2..3]
  file_path = Rails.root.join('storage', folder, subfolder, blob.key)
  
  next if File.exist?(file_path)
  
  begin
    # Criar diretórios se não existirem
    FileUtils.mkdir_p(File.dirname(file_path))
    
    # Criar uma imagem placeholder simples (1x1 pixel transparente PNG)
    if blob.content_type&.start_with?('image/')
      # Criar PNG transparente simples usando binwrite
      png_data = "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\b\x06\x00\x00\x00\x1F\x15\xC4\x89\x00\x00\x00\nIDATx\x9Cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xB4\x00\x00\x00\x00IEND\xAEB`\x82"
      File.binwrite(file_path, png_data)
      puts "✓ Placeholder criado: #{blob.filename}"
    else
      # Para outros tipos de arquivo, criar arquivo vazio
      FileUtils.touch(file_path)
      puts "✓ Arquivo vazio criado: #{blob.filename}"
    end
  rescue => e
    puts "✗ Erro ao criar #{blob.filename}: #{e.message}"
  end
end

puts "\nConcluído!"
