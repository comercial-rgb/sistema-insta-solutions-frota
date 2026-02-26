# Fix state names - acronyms are correct but names are shifted
# Usage: RAILS_ENV=production rails runner scripts/fix_state_names.rb

corrections = {
  'AC' => 'Acre',
  'AL' => 'Alagoas',
  'AP' => 'Amapá',
  'AM' => 'Amazonas',
  'BA' => 'Bahia',
  'CE' => 'Ceará',
  'DF' => 'Distrito Federal',
  'ES' => 'Espírito Santo',
  'GO' => 'Goiás',
  'MA' => 'Maranhão',
  'MS' => 'Mato Grosso do Sul',
  'MT' => 'Mato Grosso',
  'MG' => 'Minas Gerais',
  'PA' => 'Pará',
  'PB' => 'Paraíba',
  'PR' => 'Paraná',
  'PE' => 'Pernambuco',
  'PI' => 'Piauí',
  'RJ' => 'Rio de Janeiro',
  'RN' => 'Rio Grande do Norte',
  'RS' => 'Rio Grande do Sul',
  'RO' => 'Rondônia',
  'RR' => 'Roraima',
  'SC' => 'Santa Catarina',
  'SP' => 'São Paulo',
  'SE' => 'Sergipe',
  'TO' => 'Tocantins'
}

fixed = 0
State.find_each do |state|
  correct_name = corrections[state.acronym]
  next unless correct_name

  if state.name != correct_name
    puts "FIX: #{state.id} #{state.acronym} '#{state.name}' => '#{correct_name}'"
    state.update_column(:name, correct_name)
    fixed += 1
  else
    puts "OK:  #{state.id} #{state.acronym} '#{state.name}'"
  end
end

puts "\n#{fixed} estados corrigidos."
