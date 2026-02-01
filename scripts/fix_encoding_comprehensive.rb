# Script para corrigir problemas de encoding no banco de dados
# Uso: bundle exec rails runner scripts/fix_encoding_comprehensive.rb

puts "\n=========================================="
puts "  CORREÇÃO DE ENCODING - BANCO DE DADOS"
puts "==========================================\n"

# Contador de registros corrigidos
fixed_count = {
  users: 0,
  services: 0,
  order_service_statuses: 0,
  others: 0
}

# Mapeamento de caracteres corrompidos comuns
# UTF-8 mal interpretado como Latin1
encoding_fixes = {
  "????o" => "ção",
  "????" => "ç",
  "???" => "ã",
  "??" => "ó",
  "?" => "á",
  "Ã§" => "ç",
  "Ã£" => "ã",
  "Ã©" => "é",
  "Ã­" => "í",
  "Ã³" => "ó",
  "Ãº" => "ú",
  "Ã " => "à",
  "Ã¡" => "á",
  "Ãª" => "ê",
  "Ã" => "ô",
  "Ã¢" => "â",
  "Ã§Ã£" => "ção",
  "Ã§Ã" => "çõ",
}

def fix_text(text, encoding_fixes)
  return nil if text.nil?
  return text unless text.include?("?") || text.include?("Ã")
  
  fixed = text.dup
  encoding_fixes.each do |bad, good|
    fixed.gsub!(bad, good)
  end
  fixed
end

# 1. Corrigir order_service_statuses
puts "\n1. Corrigindo STATUS de ordem de serviço..."
OrderServiceStatus.where("name LIKE ?", "%?%").find_each do |status|
  original = status.name
  fixed = fix_text(status.name, encoding_fixes)
  if fixed && fixed != original
    status.update_column(:name, fixed)
    puts "   ✓ Status #{status.id}: '#{original}' → '#{fixed}'"
    fixed_count[:order_service_statuses] += 1
  end
end
puts "   Total: #{fixed_count[:order_service_statuses]} status corrigidos"

# 2. Corrigir users (clientes e fornecedores)
puts "\n2. Corrigindo USUÁRIOS/CLIENTES/FORNECEDORES..."
User.where("name LIKE ? OR fantasy_name LIKE ? OR social_name LIKE ?", "%?%", "%?%", "%?%").find_each do |user|
  updates = {}
  
  if user.name&.include?("?") || user.name&.include?("Ã")
    fixed = fix_text(user.name, encoding_fixes)
    updates[:name] = fixed if fixed && fixed != user.name
  end
  
  if user.fantasy_name&.include?("?") || user.fantasy_name&.include?("Ã")
    fixed = fix_text(user.fantasy_name, encoding_fixes)
    updates[:fantasy_name] = fixed if fixed && fixed != user.fantasy_name
  end
  
  if user.social_name&.include?("?") || user.social_name&.include?("Ã")
    fixed = fix_text(user.social_name, encoding_fixes)
    updates[:social_name] = fixed if fixed && fixed != user.social_name
  end
  
  if updates.any?
    user.update_columns(updates)
    puts "   ✓ User #{user.id}: #{updates.keys.join(', ')} corrigidos"
    fixed_count[:users] += 1
  end
end
puts "   Total: #{fixed_count[:users]} usuários corrigidos"

# 3. Corrigir services
puts "\n3. Corrigindo SERVIÇOS..."
Service.where("name LIKE ? OR description LIKE ?", "%?%", "%?%").find_each do |service|
  updates = {}
  
  if service.name&.include?("?") || service.name&.include?("Ã")
    fixed = fix_text(service.name, encoding_fixes)
    updates[:name] = fixed if fixed && fixed != service.name
  end
  
  if service.description&.include?("?") || service.description&.include?("Ã")
    fixed = fix_text(service.description, encoding_fixes)
    updates[:description] = fixed if fixed && fixed != service.description
  end
  
  if updates.any?
    service.update_columns(updates)
    puts "   ✓ Service #{service.id}: #{updates.keys.join(', ')} corrigidos"
    fixed_count[:services] += 1
  end
end
puts "   Total: #{fixed_count[:services]} serviços corrigidos"

# Resumo
puts "\n=========================================="
puts "  RESUMO DA CORREÇÃO"
puts "==========================================\n"
puts "   Status corrigidos: #{fixed_count[:order_service_statuses]}"
puts "   Usuários corrigidos: #{fixed_count[:users]}"
puts "   Serviços corrigidos: #{fixed_count[:services]}"
puts "\n✅ Correção concluída!\n"
