# Correção completa de todas as cidades
conn = ActiveRecord::Base.connection

puts "=" * 60
puts "CORREÇÃO COMPLETA DAS CIDADES"
puts "=" * 60

# Todas as correções necessárias baseadas nos problemas encontrados
all_corrections = [
  # Padrões gerais
  ['Cámara', 'Câmara'],
  ['Cándido', 'Cândido'],
  ['Antánio', 'Antônio'],
  ['Gráude', 'Grande'],
  ['Tráns', 'Trans'],
  ['Viçãosa', 'Viçosa'],
  ['Acaraç', 'Acaraú'],
  ['Acauç', 'Acauã'],
  ['Aceguç', 'Aceguá'],
  ['Acreána', 'Acrelândia'],
  ['Çásar', 'César'],
  ['Cásar', 'César'],
  ['Fálix', 'Félix'],
  ['Josá', 'José'],
  ['Josç', 'José'],
  ['Máe', 'Mãe'],
  ['máe', 'mãe'],
  ['João Cámara', 'João Câmara'],
  ['Acaraú', 'Acaraú'],  # já está certo
  ['Gáes', 'Gões'],
  ['Gáis', 'Góis'],
  ['Goiçs', 'Goiás'],
  ['Piauç', 'Piauí'],
  ['ábidos', 'Óbidos'],
  ['árico', 'Érico'],
  ['Cáu', 'Céu'],
  ['Caç', 'Caí'],
  ['Caçba', 'Caíba'],
  ['Leção', 'Leão'],
  ['Coraçáes', 'Corações'],
  ['Coraçáo', 'Coração'],
  ['Bázios', 'Búzios'],
  ['Corrça', 'Corrêa'],
  ['Traiçáo', 'Traição'],
  ['Pração', 'Praça'],
  ['Camboriç', 'Camboriú'],
  ['Baçã', 'Baía'],
  ['Baição', 'Baião'],
  ['Melgação', 'Melgaço'],
  ['Rincáo', 'Rincão'],
  ['Castelándia', 'Castelândia'],
  ['Cocaçba', 'Cocaíba'],
  ['çba', 'íba'],
  ['Cabrália', 'Cabrália'],  # já está certo
  ['Cássia', 'Cássia'],  # já está certo
  ['Cáu', 'Céu'],
  ['Praçã', 'Praça'],
  ['Peçãs', 'Peças'],
  ['Maracaná', 'Maracanã'],
  ['Paraná', 'Paraná'],  # já está certo
  ['Sapucaá', 'Sapucaí'],
  ['Piçarras', 'Piçarras'],  # já está certo
  ['Icá', 'Icó'],
  ['Jucás', 'Jucás'],  # já está certo
  ['Jucçs', 'Jucás'],
  ['Graçã', 'Graça'],
  ['Lucália', 'Lucélia'],
  ['Touçánho', 'Tucuruí'],
  ['Maurácio', 'Maurício'],
  ['Eugánio', 'Eugênio'],
  ['Cárrego', 'Córrego'],
  ['Cámara', 'Câmara'],
  ['Cánego', 'Cônego'],
  ['Cárregos', 'Córregos'],
  ['Alcántara', 'Alcântara'],
  ['Chapadáo', 'Chapadão'],
  ['Chapecá', 'Chapecó'],
  ['Cirçaco', 'Ciríaco'],
  ['Conceiçáo', 'Conceição'],
  ['Consolaçáo', 'Consolação'],
  ['Coraçáo', 'Coração'],
  ['Cornálio', 'Cornélio'],
  ['Procápio', 'Procópio'],
  ['Damição', 'Damião'],
  ['Divinápolis', 'Divinópolis'],
  ['Cárregos', 'Córregos'],
  ['Irmáos', 'Irmãos'],
  ['Inocáncio', 'Inocêncio'],
  ['Viçãoso', 'Viçoso'],
  ['Estaçáo', 'Estação'],
  ['Cámara', 'Câmara'],
  ['Caldáo', 'Caldão'],
  ['Sebastição', 'Sebastião'],
  ['Julição', 'Julião'],
  ['Carápio', 'Carápino'],
  ['Caçã', 'Caçá'],
  ['Capáes', 'Capões'],
  ['Capáo', 'Capão'],
  ['Patrocánio', 'Patrocínio'],
  ['Gervásio', 'Gervásio'],  # já está certo
  ['Leánidas', 'Leônidas'],
  ['Poáo', 'Poço'],
  ['Caráúba', 'Caraúba'],
  ['Caráôbas', 'Carnaúbas'],
  ['Caranába', 'Caranãba'],
  ['Caraôba', 'Carnaúba'],
  ['Caraôbas', 'Carnaúbas'],
  ['Joaçãba', 'Joaçaba'],
  ['Bração', 'Braço'],
  ['Caracaraç', 'Caracaraí'],
  ['Marcaçáo', 'Marcação'],
  ['Maricá', 'Maricá'],  # já está certo
  ['Mário', 'Mário'],  # já está certo
  ['Peçanha', 'Peçanha'],  # já está certo
  ['Regeneraçáo', 'Regeneração'],
  ['Renascença', 'Renascença'],  # já está certo
  ['Cabaçãl', 'Cabaçal'],
  ['Riacháo', 'Riachão'],
  ['Ribeiráo', 'Ribeirão'],
  ['Rosário', 'Rosário'],  # já está certo
  ['Paváo', 'Pavão'],
  ['Capibaribe', 'Capibaribe'],  # já está certo
  ['Cambucá', 'Cambucá'],  # já está certo
  ['Jacará', 'Jacaraú'],
  ['Sapucaç', 'Sapucaí'],
  ['Alcántara', 'Alcântara'],
  ['Aracanguç', 'Aracanguá'],
  ['Caiuç', 'Caiuá'],
  ['Içá', 'Içá'],  # já está certo
  ['Gurguçia', 'Gurguéia'],
  ['Bicas', 'Bicas'],  # já está certo
  ['Aliança', 'Aliança'],  # já está certo
  ['Aliança', 'Aliança'],  # já está certo
  ['Cará', 'Caru'],
  ['Calçado', 'Calçado'],  # já está certo
  ['Calçãdo', 'Calçado'],
  ['Julição', 'Julião'],
  ['Campos', 'Campos'],  # já está certo
  ['Campáes', 'Campões'],
  ['água', 'Água'],
  ['Unição', 'União'],
  ['Palhoça', 'Palhoça'],  # já está certo
  ['Palhaça', 'Palhoça'],
  ['Vacaria', 'Vacaria'],  # já está certo
  ['Valença', 'Valença'],  # já está certo
  ['Várzea', 'Várzea'],  # já está certo
  ['Vicáncia', 'Vicência'],
  ['Doca', 'Doca'],  # já está certo
  ['Zortça', 'Zortéa'],
  ['Açácar', 'Açúcar'],
  ['Castelhano', 'Castelhano'],  # já está certo
  ['Franca', 'Franca'],  # já está certo
  ['Franciscápolis', 'Franciscópolis'],
  ['Garça', 'Garça'],  # já está certo
  ['Gavição', 'Gavião'],
  ['Glicário', 'Glicério'],
  ['Guaraçãá', 'Guaraçaí'],
  ['Guaraqueçaba', 'Guaraqueçaba'],  # já está certo
  ['Napoleção', 'Napoleão'],
  ['Ibiassucá', 'Ibiassucê'],
  ['Ibicará', 'Ibicará'],  # já está certo
  ['Ibicaraç', 'Ibicaraí'],
  ['Icám', 'Icém'],
  ['Icapuç', 'Icapuí'],
  ['Içara', 'Içara'],  # já está certo
  ['Icaraçma', 'Icaraíma'],
  ['Ilicánea', 'Ilicínea'],
  ['Inocáncia', 'Inocência'],
  ['Irecá', 'Irecê'],
  ['Isaçãs', 'Isaías'],
  ['Itaçca', 'Itaóca'],
  ['Itaiçaba', 'Itaiçaba'],  # já está certo
  ['Itambaracá', 'Itambaracá'],  # já está certo
  ['Jaçãná', 'Jaçanã'],
  ['Jacará', 'Jacaraú'],
  ['Jaicás', 'Jaicós'],
  ['Jálio', 'Júlio'],
  ['Jericá', 'Jericó'],
  ['Jiquiriçá', 'Jiquiriçá'],  # já está certo
  ['Leção', 'Leão'],
  ['Lagoa Seca', 'Lagoa Seca'],  # já está certo
  ['Carapá', 'Carapã'],
  ['Lucália', 'Lucélia'],
  ['Maçãmbara', 'Maçambará'],
  ['Macaôba', 'Macaíba'],
  ['Macaôbas', 'Macaúbas'],
  ['Macapá', 'Macapá'],  # já está certo
  ['Maracaç', 'Maracaí'],
  ['Maracaçumá', 'Maracaçumé'],
  ['Maracaná', 'Maracanã'],
  ['Maracanaç', 'Maracanaú'],
  ['Marcaçáo', 'Marcação'],
  ['Marianápolis', 'Marianópolis'],
  ['Mato Castelhano', 'Mato Castelhano'],  # já está certo
  ['Maurilândia', 'Maurilândia'],  # já está certo
  ['Mendonça', 'Mendonça'],  # já está certo
  ['Mercás', 'Mercês'],
  ['Miracatu', 'Miracatu'],  # já está certo
  ['Mococa', 'Mococa'],  # já está certo
  ['Mojuç', 'Mojuí'],
  ['Mombaçã', 'Mombaça'],
  ['Mombuca', 'Mombuca'],  # já está certo
  ['Mormação', 'Mormaço'],
  ['Motuca', 'Motuca'],  # já está certo
  ['Mucajaç', 'Mucajaí'],
  ['Muribeca', 'Muribeca'],  # já está certo
  ['Peçanha', 'Peçanha'],  # já está certo
  ['Nilo Peçanha', 'Nilo Peçanha'],  # já está certo
  ['Graçãs', 'Graças'],
  ['Amárica', 'América'],
  ['Araçá', 'Araçá'],  # já está certo
  ['Candelária', 'Candelária'],  # já está certo
  ['Mádica', 'Módica'],
  ['Viçãosa', 'Viçosa'],
  ['Ocauçu', 'Ocauçu'],  # já está certo
  ['Olivença', 'Olivença'],  # já está certo
  ['Orocá', 'Orocó'],
  ['Otacálio', 'Otacílio'],
  ['Pação', 'Paço'],
  ['Pacaraima', 'Pacaraima'],  # já está certo
  ['Paiçandu', 'Paiçandu'],  # já está certo
  ['Esperidição', 'Esperidião'],
  ['Patrocánio', 'Patrocínio'],
  ['Paulicáia', 'Paulicéia'],
  ['Pejuçara', 'Pejuçara'],  # já está certo
  ['Piaçãbuçu', 'Piaçabuçu'],
  ['Piancá', 'Piancó'],
  ['Cafá', 'Café'],
  ['Piçarra', 'Piçarra'],  # já está certo
  ['Piláo', 'Pilão'],
  ['Piracaia', 'Piracaia'],  # já está certo
  ['Piracanjuba', 'Piracanjuba'],  # já está certo
  ['Piracicaba', 'Piracicaba'],  # já está certo
  ['Placas', 'Placas'],  # já está certo
  ['Plácido', 'Plácido'],  # já está certo
  ['Poáos', 'Poços'],
  ['Porecatu', 'Porecatu'],  # já está certo
  ['Rebouças', 'Rebouças'],  # já está certo
  ['Restinga Seca', 'Restinga Seca'],  # já está certo
  ['Bacamarte', 'Bacamarte'],  # já está certo
  ['Cascalheira', 'Cascalheira'],  # já está certo
  ['Gonçalves', 'Gonçalves'],  # já está certo
  ['Rincáo', 'Rincão'],
  ['Conceiçáo', 'Conceição'],
  ['Sales', 'Sales'],  # já está certo
  ['Siqueira Campos', 'Siqueira Campos'],  # já está certo
  ['Sorocaba', 'Sorocaba'],  # já está certo
  ['Tacaimbá', 'Tacaimbó'],
  ['Tacaratu', 'Tacaratu'],  # já está certo
  ['Tarauacá', 'Tarauacá'],  # já está certo
  ['Tejuçuoca', 'Tejuçuoca'],  # já está certo
  ['Tocantânia', 'Tocantínia'],
  ['Tocantinápolis', 'Tocantinópolis'],
  ['Toupçánho', 'Tucuruí'],
  ['Cachoeiras', 'Cachoeiras'],  # já está certo
  ['Urucânia', 'Urucânia'],  # já está certo
  ['Urucará', 'Urucará'],  # já está certo
  ['Uruçuca', 'Uruçuca'],  # já está certo
  ['Uruoca', 'Uruoca'],  # já está certo
  ['Vargeção', 'Vargem'],
  ['Zortça', 'Zortéa'],
  ['Zacarias', 'Zacarias'],  # já está certo
  
  # Padrões mais específicos
  ['Aparçcida', 'Aparecida'],
  ['Concárdia', 'Concórdia'],
  ['Descendáncia', 'Descendência'],
  ['Euzábio', 'Eusébio'],
  ['Gráupias', 'Grâupias'],
  ['Hidrolândia', 'Hidrolândia'],  # já está certo
  ['Jacará', 'Jacaraú'],
  ['Jerámimo', 'Jerônimo'],
  ['Leánidas', 'Leônidas'],
  ['Maduráira', 'Madureira'],
  ['Maracacçmá', 'Maracaçumé'],
  ['Massacá', 'Massacará'],
  ['Paraçba', 'Paraíba'],
  ['Paranaôba', 'Paranaíba'],
  ['Pernambçco', 'Pernambuco'],
  ['Piratinçnga', 'Piratininga'],
  ['Poráo', 'Porção'],
  ['Princápe', 'Príncipe'],
  ['Princápio', 'Princípio'],
  ['Procápio', 'Procópio'],
  ['Regeneraçáo', 'Regeneração'],
  ['Renascença', 'Renascença'],  # já está certo
  ['Redenção', 'Redenção'],  # já está certo
  ['Ribeiráo', 'Ribeirão'],
  ['Rosário', 'Rosário'],  # já está certo
  ['Sapçcaia', 'Sapucaia'],
  ['Satçbinha', 'Satubinha'],
  ['Sebastição', 'Sebastião'],
  ['Seropádica', 'Seropédica'],
  ['Tabocáo', 'Tabocão'],
  ['Taipçs', 'Taipas'],
  ['Tarquânio', 'Tarquínio'],
  ['Tejçpió', 'Tejupió'],
  ['Tocantânia', 'Tocantínia'],
  ['Tucçrui', 'Tucuruí'],
  ['Unição', 'União'],
  ['Vitária', 'Vitória'],
  ['árico', 'Érico']
]

# Remover correções duplicadas ou já corretas
corrections_to_apply = all_corrections.select do |wrong, correct|
  wrong != correct && wrong.include?('á') || wrong.include?('ç') || wrong.include?('Ç') || wrong.include?('ã') || wrong.include?('ô')
end.uniq

puts "\nAplicando #{corrections_to_apply.count} correções..."

total = 0
corrections_to_apply.each do |wrong, correct|
  begin
    sql = "UPDATE cities SET name = REPLACE(name, #{conn.quote(wrong)}, #{conn.quote(correct)}) WHERE name LIKE #{conn.quote("%#{wrong}%")}"
    conn.execute(sql)
    affected = conn.raw_connection.affected_rows rescue 0
    if affected > 0
      puts "  '#{wrong}' → '#{correct}': #{affected}"
      total += affected
    end
  rescue => e
    # ignorar erros
  end
end

puts "\nTotal de correções: #{total}"

# Verificar amostra após correções
puts "\n" + "=" * 60
puts "VERIFICAÇÃO APÓS CORREÇÕES"
puts "=" * 60

puts "\nCidades com 'São':"
City.where("name LIKE 'São%'").order(:name).limit(10).each { |c| puts "  #{c.name}" }

puts "\nCidades com 'João':"
City.where("name LIKE '%João%'").order(:name).limit(10).each { |c| puts "  #{c.name}" }

puts "\nCidades com 'Conceição':"
City.where("name LIKE '%Conceição%'").limit(5).each { |c| puts "  #{c.name}" }
