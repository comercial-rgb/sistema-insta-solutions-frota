# ================================================================
# Script de Validação das Correções Aplicadas
# ================================================================
# Execute: ruby validate_fixes.rb

puts "\n"
puts "=" * 80
puts "   VALIDAÇÃO DAS CORREÇÕES - Sistema Insta Solutions"
puts "=" * 80
puts "\n"

# Cores para output
def green(text); "\e[32m#{text}\e[0m"; end
def red(text); "\e[31m#{text}\e[0m"; end
def yellow(text); "\e[33m#{text}\e[0m"; end
def blue(text); "\e[36m#{text}\e[0m"; end

errors = []
warnings = []
successes = []

puts blue("🔍 VERIFICAÇÃO 1: Botão de salvar para Admin")
puts "-" * 80

form_file = "app/views/order_services/_form.html.erb"
if File.exist?(form_file)
  content = File.read(form_file)
  if content.include?("@current_user.admin? || @current_user.manager? || @current_user.additional?")
    successes << "✅ Botão de salvar corrigido para Admin"
    puts green("   ✅ CORRETO: Admin incluído na condição de salvar")
  else
    errors << "❌ Botão de salvar ainda não inclui Admin"
    puts red("   ❌ ERRO: Admin não incluído na condição de salvar")
  end
else
  warnings << "⚠️  Arquivo _form.html.erb não encontrado"
  puts yellow("   ⚠️  Arquivo não encontrado")
end

puts "\n"
puts blue("🔍 VERIFICAÇÃO 2: Safe Navigation em Views")
puts "-" * 80

views_to_check = [
  "app/views/order_services/show.html.erb",
  "app/views/order_services/edit.html.erb",
  "app/views/order_services/show_historic.html.erb",
  "app/views/order_services/_show_order_service_status.html.erb",
  "app/views/order_service_proposals/show_order_service_proposal.html.erb",
  "app/views/order_service_proposals/show_order_service_proposals_by_order_service.html.erb",
  "app/views/order_service_proposals/print_order_service_proposals_by_order_service.html.erb"
]

safe_nav_count = 0
views_to_check.each do |view_file|
  if File.exist?(view_file)
    content = File.read(view_file)
    # Verificar se usa safe navigation (&.) ou se não acessa .name diretamente
    if content.match?(/order_service_status&\.name/) || !content.match?(/order_service_status\.name[^&]/)
      safe_nav_count += 1
    else
      errors << "❌ #{view_file} sem safe navigation"
      puts red("   ❌ #{view_file}")
    end
  else
    warnings << "⚠️  #{view_file} não encontrado"
  end
end

if safe_nav_count == views_to_check.count { |f| File.exist?(f) }
  successes << "✅ Safe navigation aplicado em todas as views"
  puts green("   ✅ CORRETO: #{safe_nav_count} views com safe navigation")
else
  puts yellow("   ⚠️  #{safe_nav_count}/#{views_to_check.count { |f| File.exist?(f) }} views corretas")
end

puts "\n"
puts blue("🔍 VERIFICAÇÃO 3: Safe Navigation em Grids")
puts "-" * 80

grids_to_check = [
  "app/grids/order_services_grid.rb",
  "app/grids/order_service_proposals_grid.rb"
]

grid_safe_count = 0
grids_to_check.each do |grid_file|
  if File.exist?(grid_file)
    content = File.read(grid_file)
    if content.match?(/order_service_status&\.name/) || content.match?(/order_service&\.order_service_status&\.name/)
      grid_safe_count += 1
    else
      errors << "❌ #{grid_file} sem safe navigation"
      puts red("   ❌ #{grid_file}")
    end
  else
    warnings << "⚠️  #{grid_file} não encontrado"
  end
end

if grid_safe_count == grids_to_check.count { |f| File.exist?(f) }
  successes << "✅ Safe navigation aplicado em todos os grids"
  puts green("   ✅ CORRETO: #{grid_safe_count} grids com safe navigation")
else
  puts yellow("   ⚠️  #{grid_safe_count}/#{grids_to_check.count { |f| File.exist?(f) }} grids corretos")
end

puts "\n"
puts blue("🔍 VERIFICAÇÃO 4: Consistência entre app/ e production/")
puts "-" * 80

production_files = [
  ["app/views/order_services/_form.html.erb", "production/app/views/order_services/_form.html.erb"],
  ["app/views/order_services/show.html.erb", "production/app/views/order_services/show.html.erb"],
  ["app/grids/order_services_grid.rb", "production/app/grids/order_services_grid.rb"]
]

consistent_count = 0
production_files.each do |app_file, prod_file|
  if File.exist?(app_file) && File.exist?(prod_file)
    app_content = File.read(app_file)
    prod_content = File.read(prod_file)
    
    # Verificar se ambos têm as correções
    app_fixed = app_content.include?("order_service_status&.name") || app_content.include?("@current_user.admin? ||")
    prod_fixed = prod_content.include?("order_service_status&.name") || prod_content.include?("@current_user.admin? ||")
    
    if app_fixed && prod_fixed
      consistent_count += 1
    else
      errors << "❌ Inconsistência: #{app_file} vs #{prod_file}"
      puts red("   ❌ #{app_file}")
    end
  end
end

if consistent_count == production_files.count { |a, p| File.exist?(a) && File.exist?(p) }
  successes << "✅ Consistência entre app/ e production/"
  puts green("   ✅ CORRETO: Arquivos consistentes")
else
  puts yellow("   ⚠️  #{consistent_count}/#{production_files.count { |a, p| File.exist?(a) && File.exist?(p) }} consistentes")
end

puts "\n"
puts "=" * 80
puts "   RESULTADO FINAL"
puts "=" * 80
puts green("\n✅ Sucessos: #{successes.count}")
successes.each { |s| puts "   #{s}" }

if warnings.any?
  puts yellow("\n⚠️  Avisos: #{warnings.count}")
  warnings.each { |w| puts "   #{w}" }
end

if errors.any?
  puts red("\n❌ Erros: #{errors.count}")
  errors.each { |e| puts "   #{e}" }
  puts "\n"
  puts red("⚠️  ATENÇÃO: Correções incompletas! Verifique os erros acima.")
else
  puts "\n"
  puts green("=" * 80)
  puts green("   ✅ TODAS AS CORREÇÕES APLICADAS COM SUCESSO!")
  puts green("=" * 80)
  puts "\n"
  puts "📝 Próximos passos:"
  puts "   1. Execute: #{blue('rails runner check_production_status.rb')}"
  puts "   2. Verifique os IDs de status no banco"
  puts "   3. Faça commit e deploy das alterações"
  puts "\n"
end

puts "=" * 80
