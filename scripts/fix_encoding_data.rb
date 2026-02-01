# Script para corrigir encoding de dados já inseridos no banco
# Uso: bundle exec rails runner scripts/fix_encoding_data.rb

puts "=" * 60
puts "CORRIGINDO ENCODING DE DADOS NO BANCO"
puts "=" * 60

# Contador de registros atualizados
updated_count = {
  cities: 0,
  banks: 0,
  addresses: 0,
  orientation_manuals: 0
}

# 1. Corrigir Cities
puts "\n1. Corrigindo nomes de cidades..."
City.find_each do |city|
  original_name = city.name
  if original_name.present? && (original_name.include?('?') || original_name.encoding != Encoding::UTF_8)
    # Tentar corrigir encoding
    begin
      # Tenta forçar para UTF-8
      fixed_name = original_name.force_encoding('ISO-8859-1').encode('UTF-8')
      if fixed_name != original_name
        city.update_column(:name, fixed_name)
        updated_count[:cities] += 1
        puts "  ✓ City ##{city.id}: #{original_name} → #{fixed_name}"
      end
    rescue => e
      puts "  ✗ Erro ao corrigir City ##{city.id}: #{e.message}"
    end
  end
end

# 2. Corrigir Banks
puts "\n2. Corrigindo nomes de bancos..."
Bank.find_each do |bank|
  original_name = bank.name
  if original_name.present? && (original_name.include?('?') || original_name.encoding != Encoding::UTF_8)
    begin
      fixed_name = original_name.force_encoding('ISO-8859-1').encode('UTF-8')
      if fixed_name != original_name
        bank.update_column(:name, fixed_name)
        updated_count[:banks] += 1
        puts "  ✓ Bank ##{bank.id}: #{original_name} → #{fixed_name}"
      end
    rescue => e
      puts "  ✗ Erro ao corrigir Bank ##{bank.id}: #{e.message}"
    end
  end
end

# 3. Corrigir Addresses (district/bairro)
puts "\n3. Corrigindo bairros nos endereços..."
Address.where.not(district: nil).find_each do |address|
  original_district = address.district
  if original_district.present? && (original_district.include?('?') || original_district.encoding != Encoding::UTF_8)
    begin
      fixed_district = original_district.force_encoding('ISO-8859-1').encode('UTF-8')
      if fixed_district != original_district
        address.update_column(:district, fixed_district)
        updated_count[:addresses] += 1
        puts "  ✓ Address ##{address.id}: #{original_district} → #{fixed_district}"
      end
    rescue => e
      puts "  ✗ Erro ao corrigir Address ##{address.id}: #{e.message}"
    end
  end
end

# 4. Corrigir OrientationManuals
puts "\n4. Corrigindo orientation manuals..."
OrientationManual.find_each do |manual|
  changed = false
  
  # Corrigir name
  if manual.name.present? && (manual.name.include?('?') || manual.name.encoding != Encoding::UTF_8)
    begin
      fixed_name = manual.name.force_encoding('ISO-8859-1').encode('UTF-8')
      if fixed_name != manual.name
        manual.update_column(:name, fixed_name)
        changed = true
        puts "  ✓ Manual ##{manual.id} name: #{manual.name} → #{fixed_name}"
      end
    rescue => e
      puts "  ✗ Erro ao corrigir Manual ##{manual.id} name: #{e.message}"
    end
  end
  
  # Corrigir description
  if manual.description.present? && (manual.description.include?('?') || manual.description.encoding != Encoding::UTF_8)
    begin
      fixed_desc = manual.description.force_encoding('ISO-8859-1').encode('UTF-8')
      if fixed_desc != manual.description
        manual.update_column(:description, fixed_desc)
        changed = true
        puts "  ✓ Manual ##{manual.id} description corrigida"
      end
    rescue => e
      puts "  ✗ Erro ao corrigir Manual ##{manual.id} description: #{e.message}"
    end
  end
  
  updated_count[:orientation_manuals] += 1 if changed
end

# Resumo
puts "\n" + "=" * 60
puts "RESUMO"
puts "=" * 60
puts "Cities corrigidas: #{updated_count[:cities]}"
puts "Banks corrigidos: #{updated_count[:banks]}"
puts "Endereços corrigidos: #{updated_count[:addresses]}"
puts "Manuais corrigidos: #{updated_count[:orientation_manuals]}"
puts "=" * 60
puts "✓ Script concluído!"
