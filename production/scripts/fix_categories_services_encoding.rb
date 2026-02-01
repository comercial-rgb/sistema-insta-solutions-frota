# Corrigir encoding nas categorias e services

puts "=" * 60
puts "CORREÇÃO DE ENCODING - CATEGORIAS E SERVICES"
puts "=" * 60

# 1. Corrigir categorias
puts "\n1. Corrigindo categorias..."

Category.where("name LIKE '%Ü%' OR name LIKE '%î%'").each do |cat|
  old_name = cat.name
  new_name = old_name.gsub('Ü', 'ç').gsub('î', 'ç')
  
  cat.name = new_name
  if cat.save(validate: false)
    puts "  ✓ Categoria ID #{cat.id}: '#{old_name}' → '#{new_name}'"
  end
end

# 2. Corrigir nomes de services
puts "\n2. Corrigindo nomes de services..."

Service.where("name LIKE '%Ü%' OR name LIKE '%î%' OR name LIKE '%ª%'").each do |service|
  old_name = service.name
  new_name = old_name
    .gsub('Ü', 'ç')
    .gsub('î', 'ç')
    .gsub('ª', 'ª')  # Manter ordinal feminino
  
  service.name = new_name
  if service.save(validate: false)
    puts "  ✓ Service ID #{service.id}: '#{old_name.strip}' → '#{new_name.strip}'"
  end
end

# 3. Verificação final
puts "\n3. Verificação final..."

cat_remaining = Category.where("name LIKE '%Ü%' OR name LIKE '%î%'").count
svc_remaining = Service.where("name LIKE '%Ü%' OR name LIKE '%î%'").count

puts "\nCategorias com problemas: #{cat_remaining}"
puts "Services com problemas: #{svc_remaining}"

if cat_remaining == 0 && svc_remaining == 0
  puts "\n✅ TUDO CORRIGIDO!"
else
  puts "\n⚠️  Ainda há registros com problemas"
end

puts "=" * 60
