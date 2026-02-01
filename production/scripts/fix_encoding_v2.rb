# Corrigir encoding UTF-8 de usuários - Versão Melhorada

puts "=" * 60
puts "CORREÇÃO DE ENCODING UTF-8"
puts "=" * 60

# Mapeamento de caracteres corrompidos → corretos
corrections = {
  # Acentos graves/agudos/circunflexos
  'ã' => 'ã',
  'ç' => 'ç',
  'á' => 'á',
  'é' => 'é',
  'í' => 'í',
  'ó' => 'ó',
  'ú' => 'ú',
  'â' => 'â',
  'ê' => 'ê',
  'ô' => 'ô',
  'à' => 'à',
  'õ' => 'õ',
  
  # Maiúsculas
  'Ã' => 'Ã',
  'Ç' => 'Ç',
  'Á' => 'Á',
  'É' => 'É',
  'Í' => 'Í',
  'Ó' => 'Ó',
  'Ú' => 'Ú',
  'Â' => 'Â',
  'Ê' => 'Ê',
  'Ô' => 'Ô',
  'À' => 'À',
  'Õ' => 'Õ',
  
  # Outros
  'ü' => 'ü',
  'Ü' => 'Ü'
}

users_with_issues = User.where("name LIKE '%??%'")

puts "\nTotal de usuários com problemas: #{users_with_issues.count}"
puts "\nIniciando correções...\n"

corrected_count = 0
failed_count = 0

users_with_issues.each do |user|
  original_name = user.name
  corrected_name = original_name.dup
  
  # Aplicar todas as correções
  corrections.each do |wrong, correct|
    corrected_name.gsub!(wrong, correct)
  end
  
  # Se ainda tem ??, tentar corrigir manualmente casos comuns
  if corrected_name.include?('??')
    # Padrões comuns de dupla interrogação
    corrected_name.gsub!('????', 'ção')
    corrected_name.gsub!('???', 'ção')
    corrected_name.gsub!('çã', 'ção')
    corrected_name.gsub!('aç?', 'ação')
    corrected_name.gsub!('iç?', 'ição')
    corrected_name.gsub!('uç?', 'ução')
  end
  
  # Atualizar se houve mudança
  if corrected_name != original_name && !corrected_name.include?('??')
    user.name = corrected_name
    
    if user.save(validate: false)
      puts "✓ ID #{user.id}: '#{original_name}' → '#{corrected_name}'"
      corrected_count += 1
    else
      puts "✗ ID #{user.id}: Falha ao salvar '#{original_name}'"
      failed_count += 1
    end
  else
    puts "⚠ ID #{user.id}: Não foi possível corrigir automaticamente: '#{original_name}'"
    failed_count += 1
  end
end

puts "\n" + "=" * 60
puts "RESULTADO"
puts "=" * 60
puts "✅ Corrigidos: #{corrected_count}"
puts "❌ Falharam: #{failed_count}"
puts "=" * 60
