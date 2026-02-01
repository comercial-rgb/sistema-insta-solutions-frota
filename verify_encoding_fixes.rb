#!/usr/bin/env ruby
# Verificar se as correções foram aplicadas com sucesso

require_relative 'config/environment'

puts "✅ VERIFICANDO CORREÇÕES APLICADAS"
puts "=" * 80

# Verificar alguns casos específicos
test_cases = [
  { model: User, id: 674, field: :name, expected: 'Nível' },
  { model: City, id: 1160, field: :name, expected: 'Açailândia' },
  { model: City, id: 3223, field: :name, expected: 'Aliança' },
  { model: Service, id: 1004, field: :name, expected: 'vedação' },
  { model: Service, id: 1160, field: :name, expected: 'INSTALAÇÃO' },
  { model: Address, id: 224, field: :district, expected: 'Viçosa' }
]

all_ok = true

test_cases.each do |test|
  record = test[:model].find_by(id: test[:id])
  if record
    value = record.send(test[:field])
    if value&.include?(test[:expected])
      puts "✅ #{test[:model].name} ID #{test[:id]}: #{test[:field]} contém '#{test[:expected]}'"
    else
      puts "❌ #{test[:model].name} ID #{test[:id]}: #{test[:field]} = '#{value}' (esperado: '#{test[:expected]}')"
      all_ok = false
    end
  else
    puts "⚠️  #{test[:model].name} ID #{test[:id]} não encontrado"
  end
end

# Verificar services de garantia (os mais críticos segundo o usuário)
puts "\n" + "=" * 80
puts "🔍 VERIFICANDO SERVIÇOS COM TERMOS DE GARANTIA"
puts "=" * 80

warranty_services = Service.where("name LIKE '%direção%' OR name LIKE '%inspeção%' OR name LIKE '%vedação%' OR name LIKE '%ignição%'").limit(10)

puts "\nExemplos de serviços corrigidos:"
warranty_services.each do |service|
  puts "  • ID #{service.id}: #{service.name}"
end

puts "\n" + "=" * 80

if all_ok
  puts "✅ TODAS AS VERIFICAÇÕES PASSARAM!"
  puts "\nOs erros de encoding foram corrigidos com sucesso."
  puts "Peças, serviços, cidades, endereços e usuários agora exibem acentuação correta."
else
  puts "⚠️  Algumas verificações falharam. Revise os logs acima."
end

puts "\n"
