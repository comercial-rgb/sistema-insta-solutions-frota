#!/usr/bin/env ruby
# Corrige nomes de fornecedores com caracteres errados (ó no lugar de é/á/ã/ú/ç)
# RAILS_ENV=production rails runner scripts/fix_provider_names.rb

fixes = [
  # [id, campo, valor_errado, valor_correto]
  [229, :fantasy_name, 'Auto Mecânica Secretório', 'Auto Mecânica Secretário'],
  [194, :fantasy_name, 'Auto Elótrica e Mecânica Erechim', 'Auto Elétrica e Mecânica Erechim'],
  [194, :social_name, 'Auto Elótrica Erechim LTDA ME', 'Auto Elétrica Erechim LTDA ME'],
  [221, :fantasy_name, 'Auto Elótrica Avenida ', 'Auto Elétrica Avenida'],
  [221, :social_name, 'Auto Elótrica Avenida LTDA ', 'Auto Elétrica Avenida LTDA'],
  [283, :fantasy_name, 'Fabio Auto Elótrica', 'Fabio Auto Elétrica'],
  [291, :fantasy_name, 'Auto Elótrica Jair', 'Auto Elétrica Jair'],
  [292, :fantasy_name, 'Auto Elótrica Peranzoni', 'Auto Elétrica Peranzoni'],
  [292, :social_name, 'Joóo Francisco Monteiro Peranzoni LTDA', 'João Francisco Monteiro Peranzoni LTDA'],
  [321, :fantasy_name, 'G P Auto Elótrica', 'G P Auto Elétrica'],
  [253, :fantasy_name, 'Auto Lavagem e Estótica Automotiva Auto Brilho', 'Auto Lavagem e Estética Automotiva Auto Brilho'],
  [253, :social_name, 'Estótica Automotiva', 'Estética Automotiva'],
  [525, :fantasy_name, 'Piraque-Aóu Auto Eletrica', 'Piraque-Açu Auto Elétrica'],
  [677, :social_name, 'Secretaria Municipal de Saóde de Campina Grande', 'Secretaria Municipal de Saúde de Campina Grande'],
]

puts "=" * 60
puts "CORREÇÃO DE NOMES DE FORNECEDORES"
puts "=" * 60

success = 0
skipped = 0
errors = 0

fixes.each do |id, field, old_val, new_val|
  user = User.find_by(id: id)
  unless user
    puts "[ERRO] ID #{id}: Usuário não encontrado"
    errors += 1
    next
  end

  current = user.send(field).to_s
  # Verifica se o valor atual bate (pode já ter sido corrigido)
  if current.strip == old_val.strip
    user.update_column(field, new_val)
    puts "[OK]    ID #{id} #{field}: '#{old_val.strip}' => '#{new_val}'"
    success += 1
  elsif current.strip == new_val.strip
    puts "[SKIP]  ID #{id} #{field}: já está correto ('#{new_val}')"
    skipped += 1
  else
    puts "[DIFF]  ID #{id} #{field}: valor atual '#{current}' diferente do esperado '#{old_val.strip}'"
    errors += 1
  end
end

puts
puts "=" * 60
puts "RESULTADO: #{success} corrigidos, #{skipped} já corretos, #{errors} erros"
puts "=" * 60
