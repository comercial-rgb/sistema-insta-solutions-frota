# Script para corrigir TODOS os encodings restantes
# Uso: bundle exec rails runner scripts/fix_all_remaining_encoding.rb

puts "\n=========================================="
puts "  CORREÇÃO COMPLETA DE ENCODING"
puts "==========================================\n"

fixed_count = {
  provider_service_types: 0,
  contracts: 0,
  cost_centers: 0,
  commitments: 0,
  vehicles: 0,
  notifications: 0,
  orientation_manuals: 0
}

# Mapeamento de caracteres corrompidos
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

# 1. ProviderServiceType
puts "\n1. Corrigindo PROVIDER_SERVICE_TYPES..."
ProviderServiceType.where("name LIKE ? OR description LIKE ?", "%?%", "%?%").find_each do |record|
  updates = {}
  
  if record.name&.include?("?") || record.name&.include?("Ã")
    fixed = fix_text(record.name, encoding_fixes)
    updates[:name] = fixed if fixed && fixed != record.name
  end
  
  if record.description&.include?("?") || record.description&.include?("Ã")
    fixed = fix_text(record.description, encoding_fixes)
    updates[:description] = fixed if fixed && fixed != record.description
  end
  
  if updates.any?
    record.update_columns(updates)
    puts "   ✓ ProviderServiceType #{record.id}: #{updates.keys.join(', ')} corrigidos"
    fixed_count[:provider_service_types] += 1
  end
end
puts "   Total: #{fixed_count[:provider_service_types]} registros corrigidos"

# 2. Contract
puts "\n2. Corrigindo CONTRACTS..."
Contract.where("contracts.name LIKE ?", "%?%").find_each do |record|
  if record.name&.include?("?") || record.name&.include?("Ã")
    fixed = fix_text(record.name, encoding_fixes)
    if fixed && fixed != record.name
      record.update_column(:name, fixed)
      puts "   ✓ Contract #{record.id}: name corrigido"
      fixed_count[:contracts] += 1
    end
  end
end
puts "   Total: #{fixed_count[:contracts]} contratos corrigidos"

# 3. CostCenter
puts "\n3. Corrigindo COST_CENTERS..."
CostCenter.where("name LIKE ? OR description LIKE ?", "%?%", "%?%").find_each do |record|
  updates = {}
  
  if record.name&.include?("?") || record.name&.include?("Ã")
    fixed = fix_text(record.name, encoding_fixes)
    updates[:name] = fixed if fixed && fixed != record.name
  end
  
  if record.description&.include?("?") || record.description&.include?("Ã")
    fixed = fix_text(record.description, encoding_fixes)
    updates[:description] = fixed if fixed && fixed != record.description
  end
  
  if updates.any?
    record.update_columns(updates)
    puts "   ✓ CostCenter #{record.id}: #{updates.keys.join(', ')} corrigidos"
    fixed_count[:cost_centers] += 1
  end
end
puts "   Total: #{fixed_count[:cost_centers]} centros de custo corrigidos"

# 4. Commitment
puts "\n4. Corrigindo COMMITMENTS..."
Commitment.where("title LIKE ? OR description LIKE ?", "%?%", "%?%").find_each do |record|
  updates = {}
  
  if record.title&.include?("?") || record.title&.include?("Ã")
    fixed = fix_text(record.title, encoding_fixes)
    updates[:title] = fixed if fixed && fixed != record.title
  end
  
  if record.description&.include?("?") || record.description&.include?("Ã")
    fixed = fix_text(record.description, encoding_fixes)
    updates[:description] = fixed if fixed && fixed != record.description
  end
  
  if updates.any?
    record.update_columns(updates)
    puts "   ✓ Commitment #{record.id}: #{updates.keys.join(', ')} corrigidos"
    fixed_count[:commitments] += 1
  end
end
puts "   Total: #{fixed_count[:commitments]} compromissos corrigidos"

# 5. Vehicle
puts "\n5. Corrigindo VEHICLES..."
Vehicle.where("current_owner_name LIKE ? OR old_owner_name LIKE ?", "%?%", "%?%").find_each do |record|
  updates = {}
  
  if record.current_owner_name&.include?("?") || record.current_owner_name&.include?("Ã")
    fixed = fix_text(record.current_owner_name, encoding_fixes)
    updates[:current_owner_name] = fixed if fixed && fixed != record.current_owner_name
  end
  
  if record.old_owner_name&.include?("?") || record.old_owner_name&.include?("Ã")
    fixed = fix_text(record.old_owner_name, encoding_fixes)
    updates[:old_owner_name] = fixed if fixed && fixed != record.old_owner_name
  end
  
  if updates.any?
    record.update_columns(updates)
    puts "   ✓ Vehicle #{record.id}: #{updates.keys.join(', ')} corrigidos"
    fixed_count[:vehicles] += 1
  end
end
puts "   Total: #{fixed_count[:vehicles]} veículos corrigidos"

# 6. Notification
puts "\n6. Corrigindo NOTIFICATIONS..."
Notification.where("title LIKE ? OR message LIKE ?", "%?%", "%?%").find_each do |record|
  updates = {}
  
  if record.title&.include?("?") || record.title&.include?("Ã")
    fixed = fix_text(record.title, encoding_fixes)
    updates[:title] = fixed if fixed && fixed != record.title
  end
  
  if record.message&.include?("?") || record.message&.include?("Ã")
    fixed = fix_text(record.message, encoding_fixes)
    updates[:message] = fixed if fixed && fixed != record.message
  end
  
  if updates.any?
    record.update_columns(updates)
    puts "   ✓ Notification #{record.id}: #{updates.keys.join(', ')} corrigidos"
    fixed_count[:notifications] += 1
  end
end
puts "   Total: #{fixed_count[:notifications]} notificações corrigidas"

# 7. OrientationManual
puts "\n7. Corrigindo ORIENTATION_MANUALS..."
OrientationManual.where("name LIKE ? OR description LIKE ?", "%?%", "%?%").find_each do |record|
  updates = {}
  
  if record.name&.include?("?") || record.name&.include?("Ã")
    fixed = fix_text(record.name, encoding_fixes)
    updates[:name] = fixed if fixed && fixed != record.name
  end
  
  if record.description&.include?("?") || record.description&.include?("Ã")
    fixed = fix_text(record.description, encoding_fixes)
    updates[:description] = fixed if fixed && fixed != record.description
  end
  
  if updates.any?
    record.update_columns(updates)
    puts "   ✓ OrientationManual #{record.id}: #{updates.keys.join(', ')} corrigidos"
    fixed_count[:orientation_manuals] += 1
  end
end
puts "   Total: #{fixed_count[:orientation_manuals]} manuais corrigidos"

# Resumo final
puts "\n=========================================="
puts "  RESUMO DA CORREÇÃO"
puts "==========================================\n"
total = fixed_count.values.sum
puts "   ProviderServiceTypes: #{fixed_count[:provider_service_types]}"
puts "   Contracts: #{fixed_count[:contracts]}"
puts "   CostCenters: #{fixed_count[:cost_centers]}"
puts "   Commitments: #{fixed_count[:commitments]}"
puts "   Vehicles: #{fixed_count[:vehicles]}"
puts "   Notifications: #{fixed_count[:notifications]}"
puts "   OrientationManuals: #{fixed_count[:orientation_manuals]}"
puts "\n   TOTAL: #{total} registros corrigidos"
puts "\n✅ Correção completa concluída!\n"
