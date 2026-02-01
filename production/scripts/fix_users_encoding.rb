# Corrige encoding de usuários
puts "Corrigindo encoding de usuários..."

corrections = {
  'F??bio' => 'Fábio',
  '??lio' => 'Élio',
  'Ant??nio' => 'Antônio',
  'Louren??o' => 'Lourenço',
  'Eliz??ngela' => 'Elizângela',
  'Jos??' => 'José',
  'Tayn??' => 'Tayná',
  'Servi??o' => 'Serviço',
  'Integra????o' => 'Integração',
  'Jo??o' => 'João',
  'M??nica' => 'Mônica',
  'Andr??' => 'André',
  'Concei????o' => 'Conceição',
  'Jer??nimo' => 'Jerônimo',
  'C??sar' => 'César',
  'F??tima' => 'Fátima',
  'In??cio' => 'Inácio',
  'R??mulo' => 'Rômulo',
  'Patr??cia' => 'Patrícia',
  'M??ximo' => 'Máximo',
  'Cl??udia' => 'Cláudia',
  'F??bio' => 'Fábio',
  'Vit??ria' => 'Vitória',
  'Caet??' => 'Caetá',
  'Th???' => 'Thá',
  'J??nior' => 'Júnior',
  'V??nia' => 'Vânia',
  'R??gia' => 'Régia',
  'Fl??via' => 'Flávia',
  'L??cia' => 'Lúcia',
  'M??rcia' => 'Márcia',
  'S??rgio' => 'Sérgio',
  'T??nia' => 'Tânia',
  'Vit??rio' => 'Vitório',
  'Rog??rio' => 'Rogério'
}

users = User.where("name LIKE ?", "%?%")
puts "Total de usuários a corrigir: #{users.count}"

fixed = 0
users.find_each do |user|
  original = user.name
  new_name = user.name
  
  corrections.each do |wrong, correct|
    new_name = new_name.gsub(wrong, correct)
  end
  
  if new_name != original
    user.update_column(:name, new_name)
    fixed += 1
    puts "  ✓ ID #{user.id}: #{original} → #{new_name}"
  end
end

puts "\n✅ Corrigidos: #{fixed} usuários"
