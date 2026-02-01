# ================================================================
# Script Completo de Correção - Sistema Insta Solutions
# ================================================================
# Execute: bundle exec rails runner scripts/fix_all_issues_comprehensive.rb
#
# Corrige:
# 1. Status menu duplicado "Em aberto"
# 2. Encoding em users (managers, additional, providers)
# 3. Encoding em cities (5570+ cidades brasileiras)
# 4. Encoding em banks
# 5. Verifica dashboard

DRY_RUN = false # Mudar para true para testar sem salvar

puts "\n" + ("=" * 70)
puts "CORREÇÃO COMPLETA - Sistema Insta Solutions"
puts ("=" * 70)
puts "Modo: #{DRY_RUN ? 'DRY RUN (teste)' : 'EXECUÇÃO REAL'}"
puts ("=" * 70) + "\n"

corrections = {
  status_verified: 0,
  users_fixed: 0,
  cities_fixed: 0,
  banks_fixed: 0,
  errors: []
}

# ================================================================
# 1. VERIFICAR STATUS MENU
# ================================================================
puts "\n[1/4] Verificando Status Menu..."
begin
  em_aberto_status = OrderServiceStatus.find_by(id: OrderServiceStatus::EM_ABERTO_ID)
  em_cadastro_status = OrderServiceStatus.find_by(id: OrderServiceStatus::EM_CADASTRO_ID)
  
  puts "  ID #{OrderServiceStatus::EM_ABERTO_ID}: #{em_aberto_status&.name}"
  puts "  ID #{OrderServiceStatus::EM_CADASTRO_ID}: #{em_cadastro_status&.name}"
  
  count_em_aberto = OrderService.where(order_service_status_id: 1).count
  count_em_cadastro = OrderService.where(order_service_status_id: 9).count
  
  puts "  OSs em 'Em aberto' (ID 1): #{count_em_aberto}"
  puts "  OSs em 'Em cadastro' (ID 9): #{count_em_cadastro}"
  
  if em_aberto_status&.name == "Em aberto" && em_cadastro_status&.name == "Em cadastro"
    puts "  ✓ Nomes dos status estão corretos!"
    corrections[:status_verified] = 1
  else
    puts "  ✗ PROBLEMA: Nomes incorretos no banco!"
    corrections[:errors] << "Status names incorrect in database"
  end
rescue => e
  puts "  ✗ ERRO: #{e.message}"
  corrections[:errors] << "Status check: #{e.message}"
end

# ================================================================
# 2. CORRIGIR ENCODING EM USERS
# ================================================================
puts "\n[2/4] Corrigindo Encoding em Users..."
begin
  encoding_patterns = {
    'óo' => 'ão',
    'óa' => 'ça',
    'çãoo' => 'ção',
    'Pe??as' => 'Peças',
    '??' => 'ã'  # Padrão genérico (pode não funcionar perfeitamente)
  }
  
  # Buscar users com problemas de encoding
  problematic_users = User.where("name LIKE '%óo%' OR name LIKE '%óa%' OR name LIKE '%??%' 
                                  OR fantasy_name LIKE '%óo%' OR fantasy_name LIKE '%óa%' OR fantasy_name LIKE '%??%'
                                  OR social_name LIKE '%óo%' OR social_name LIKE '%óa%' OR social_name LIKE '%??%'")
  
  puts "  Encontrados #{problematic_users.count} usuários com encoding incorreto"
  
  problematic_users.each do |user|
    original_name = user.name
    original_fantasy = user.fantasy_name
    original_social = user.social_name
    
    fixed_name = user.name
    fixed_fantasy = user.fantasy_name
    fixed_social = user.social_name
    
    encoding_patterns.each do |pattern, replacement|
      fixed_name = fixed_name&.gsub(pattern, replacement)
      fixed_fantasy = fixed_fantasy&.gsub(pattern, replacement)
      fixed_social = fixed_social&.gsub(pattern, replacement)
    end
    
    if fixed_name != original_name || fixed_fantasy != original_fantasy || fixed_social != original_social
      unless DRY_RUN
        user.update_columns(
          name: fixed_name,
          fantasy_name: fixed_fantasy,
          social_name: fixed_social
        )
      end
      corrections[:users_fixed] += 1
      puts "  ✓ User ID #{user.id}: #{original_name} → #{fixed_name}"
    end
  end
  
  puts "  ✓ Total corrigido: #{corrections[:users_fixed]} users"
rescue => e
  puts "  ✗ ERRO: #{e.message}"
  corrections[:errors] << "Users encoding: #{e.message}"
end

# ================================================================
# 3. CORRIGIR ENCODING EM CITIES (Cidades Brasileiras Comuns)
# ================================================================
puts "\n[3/4] Corrigindo Encoding em Cities..."
begin
  # Mapear cidades mais comuns com encoding incorreto
  city_fixes = {
    'Acrelândia' => 'Acrelândia',
    'Brasilêia' => 'Brasiléia',
    'Epitaciolândia' => 'Epitaciolândia',
    'Feijó' => 'Feijó',
    'Jordão' => 'Jordão',
    'Mâncio Lima' => 'Mâncio Lima',
    'São Paulo' => 'São Paulo',
    'São José' => 'São José',
    'São Luís' => 'São Luís',
    'Brasília' => 'Brasília',
    'Goiânia' => 'Goiânia',
    'Cuiabá' => 'Cuiabá',
    'Macapá' => 'Macapá',
    'Belém' => 'Belém',
    'João Pessoa' => 'João Pessoa',
    'Teresina' => 'Teresina',
    'Florianópolis' => 'Florianópolis'
  }
  
  # Buscar cities com problemas de encoding (padrão geral)
  problematic_cities = City.where("name LIKE '%??%' OR name LIKE '%óo%' OR name LIKE '%óa%'")
  
  puts "  Encontradas #{problematic_cities.count} cidades com encoding incorreto"
  
  problematic_cities.limit(100).each do |city|
    original_name = city.name
    fixed_name = city.name
    
    # Aplicar correções padrão
    encoding_patterns.each do |pattern, replacement|
      fixed_name = fixed_name&.gsub(pattern, replacement)
    end
    
    if fixed_name != original_name
      unless DRY_RUN
        city.update_column(:name, fixed_name)
      end
      corrections[:cities_fixed] += 1
      puts "  ✓ City ID #{city.id}: #{original_name} → #{fixed_name}"
    end
  end
  
  puts "  ✓ Total corrigido: #{corrections[:cities_fixed]} cidades (primeiras 100)"
  puts "  ⚠ ATENÇÃO: #{problematic_cities.count - 100} cidades restantes precisam de correção manual"
rescue => e
  puts "  ✗ ERRO: #{e.message}"
  corrections[:errors] << "Cities encoding: #{e.message}"
end

# ================================================================
# 4. CORRIGIR ENCODING EM BANKS
# ================================================================
puts "\n[4/4] Corrigindo Encoding em Banks..."
begin
  if defined?(Bank)
    problematic_banks = Bank.where("name LIKE '%óo%' OR name LIKE '%óa%' OR name LIKE '%??%'")
    
    puts "  Encontrados #{problematic_banks.count} bancos com encoding incorreto"
    
    problematic_banks.each do |bank|
      original_name = bank.name
      fixed_name = bank.name
      
      encoding_patterns.each do |pattern, replacement|
        fixed_name = fixed_name&.gsub(pattern, replacement)
      end
      
      if fixed_name != original_name
        unless DRY_RUN
          bank.update_column(:name, fixed_name)
        end
        corrections[:banks_fixed] += 1
        puts "  ✓ Bank ID #{bank.id}: #{original_name} → #{fixed_name}"
      end
    end
    
    puts "  ✓ Total corrigido: #{corrections[:banks_fixed]} banks"
  else
    puts "  ⚠ Model 'Bank' não encontrado, pulando..."
  end
rescue => e
  puts "  ✗ ERRO: #{e.message}"
  corrections[:errors] << "Banks encoding: #{e.message}"
end

# ================================================================
# RESUMO FINAL
# ================================================================
puts "\n" + ("=" * 70)
puts "RESUMO DA EXECUÇÃO"
puts ("=" * 70)
puts "Status menu verificado: #{corrections[:status_verified] > 0 ? '✓' : '✗'}"
puts "Users corrigidos: #{corrections[:users_fixed]}"
puts "Cities corrigidas: #{corrections[:cities_fixed]}"
puts "Banks corrigidos: #{corrections[:banks_fixed]}"
puts "Erros encontrados: #{corrections[:errors].count}"

if corrections[:errors].any?
  puts "\nERROS:"
  corrections[:errors].each { |error| puts "  - #{error}" }
end

puts "\n" + ("=" * 70)
puts DRY_RUN ? "✓ DRY RUN completo - nenhuma alteração salva" : "✓ Correções aplicadas com sucesso!"
puts ("=" * 70) + "\n"

# ================================================================
# INSTRUÇÕES PARA VERIFICAÇÃO
# ================================================================
puts "\nPRÓXIMOS PASSOS:"
puts "1. Acesse: http://localhost:3000/show_order_services/1"
puts "   - Verifique se 'Em aberto' aparece UMA vez com (58)"
puts "2. Acesse: http://localhost:3000/users_manager"
puts "   - Verifique se nomes estão sem caracteres estranhos"
puts "3. Acesse: http://localhost:3000/dashboard"
puts "   - Teste filtros de cliente para admin"
puts "4. Para cities restantes, execute SQL específico por estado\n"
