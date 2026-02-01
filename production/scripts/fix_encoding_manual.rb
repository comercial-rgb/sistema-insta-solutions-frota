# Script para CORRIGIR encoding - substituições diretas usando SQL
# Uso: bundle exec rails runner scripts/fix_encoding_manual.rb

conn = ActiveRecord::Base.connection

puts "=" * 70
puts "CORRIGINDO ENCODING - SUBSTITUIÇÕES DIRETAS"
puts "=" * 70

# Mapeamento de caracteres corrompidos para corretos
# No banco MySQL: ?? representa caracteres acentuados
replacements = [
  ['??o', 'ão'],
  ['??a', 'ça'],
  ['??e', 'çe'],
  ['??i', 'çi'],
  ['??u', 'çu'],
  ['????o', 'ção'],
  ['????es', 'ções'],
  ['S??o', 'São'],
  ['Jo??o', 'João'],
  ['J??lio', 'Júlio'],
  ['M??rio', 'Mário'],
  ['Am??rica', 'América'],
  ['Gl??ria', 'Glória'],
  ['Get??lio', 'Getúlio'],
  ['Ant??nio', 'Antônio'],
  ['Jos??', 'José'],
  ['Econ??mica', 'Econômica'],
  ['Ita??', 'Itaú'],
  ['M??ltiplo', 'Múltiplo'],
  ['Ip??', 'Ipê'],
  ['Igua??u', 'Iguaçu'],
  ['F??sica', 'Física'],
  ['Jur??dica', 'Jurídica'],
  ['Servi??o', 'Serviço'],
  ['servi??o', 'serviço'],
  ['ve??culo', 'veículo'],
  ['Ve??culo', 'Veículo'],
  ['pe??a', 'peça'],
  ['Pe??a', 'Peça'],
  ['Petr??polis', 'Petrópolis'],
  ['Tr??s', 'Três'],
  ['Goi??s', 'Goiás'],
  ['Paran??', 'Paraná'],
  ['Par??', 'Pará'],
  ['Cear??', 'Ceará'],
  ['Maranh??o', 'Maranhão'],
  ['Rond??nia', 'Rondônia'],
  ['Amap??', 'Amapá'],
  ['Piau??', 'Piauí'],
  ['Gon??alves', 'Gonçalves'],
  ['Ven??ncio', 'Venâncio'],
  ['Fran??a', 'França'],
  ['Louren??o', 'Lourenço'],
  ['Marc??lio', 'Marcílio'],
  ['Vit??ria', 'Vitória'],
  ['Boqueir??o', 'Boqueirão'],
  ['Exposi????o', 'Exposição'],
  ['Concei????o', 'Conceição'],
  ['Opera????o', 'Operação'],
  ['Jun????o', 'Junção'],
  ['Na????es', 'Nações'],
  ['Orienta????o', 'Orientação'],
  ['instru????es', 'instruções'],
  ['Ceil??ndia', 'Ceilândia'],
  ['Guar??', 'Guará'],
  ['Rodovi??rio', 'Rodoviário'],
  ['Universit??rio', 'Universitário'],
  ['Expedicion??rio', 'Expedicionário'],
  ['Eletricit??rios', 'Eletricitários'],
  ['Metal??rgicos', 'Metalúrgicos'],
  ['Banc??rio', 'Bancário'],
  ['Capit??o', 'Capitão'],
  ['Ol??mpio', 'Olímpio'],
  ['Os??rio', 'Osório'],
  ['Bonif??cio', 'Bonifácio'],
  ['Patroc??nio', 'Patrocínio'],
  ['Ger??ncio', 'Gerâncio'],
  ['Pl??cido', 'Plácido'],
  ['Apar??cio', 'Aparício'],
  ['Camar??o', 'Camarão'],
  ['Esp??ndola', 'Espíndola'],
  ['Hidr??ulica', 'Hidráulica'],
  ['hidr??ulic', 'hidráulic'],
  ['El??tric', 'Elétric'],
  ['el??tric', 'elétric'],
  ['Farm??cia', 'Farmácia'],
  ['farm??cia', 'farmácia'],
  ['Sa??de', 'Saúde'],
  ['sa??de', 'saúde'],
  ['N??vel', 'Nível'],
  ['n??vel', 'nível'],
  ['P??blic', 'Públic'],
  ['p??blic', 'públic'],
  ['Aut??nom', 'Autônom'],
  ['aut??nom', 'autônom'],
  ['Coordena????o', 'Coordenação'],
  ['Aperfei??oamento', 'Aperfeiçoamento'],
  ['Galp??o', 'Galpão'],
  ['Barrac??o', 'Barracão'],
  ['Pra??a', 'Praça'],
  ['Crist??v??o', 'Cristóvão'],
  ['Peregrino', 'Peregrino'],
  ['Tarum??', 'Tarumã'],
  ['Maur??cio', 'Maurício'],
  ['Cer??mica', 'Cerâmica'],
  ['Higien??polis', 'Higienópolis'],
  ['Oper??ria', 'Operária'],
  ['Indai??', 'Indaiá'],
  ['Cambori??', 'Camboriú'],
  ['Bel??m', 'Belém'],
  ['Provid??ncia', 'Providência'],
  ['Cobil??ndia', 'Cobilândia'],
  ['Lac??', 'Lacê'],
  ['Maril??ndia', 'Marilândia'],
  ['Independ??ncia', 'Independência'],
  ['Sebasti??o', 'Sebastião'],
  ['Am??lia', 'Amélia'],
  ['Guaran??', 'Guaraná'],
  ['Gir??o', 'Girão'],
  ['S??tio', 'Sítio'],
  ['Itacib??', 'Itacibá'],
  ['Cana??', 'Canaã'],
  ['V??rzea', 'Várzea'],
  ['Para??so', 'Paraíso'],
  ['Ros??rio', 'Rosário'],
  ['F??tima', 'Fátima'],
  ['Jetib??', 'Jetibá'],
  ['??rea', 'Área'],
  ['Rep??blica', 'República'],
  ['Basil??ia', 'Basiléia'],
  ['Bras??lia', 'Brasília'],
  ['S??rgio', 'Sérgio'],
  ['Rog??rio', 'Rogério'],
  ['Ibira??u', 'Ibiraçu'],
  ['Azal??ias', 'Azaléias'],
  ['Ferrabr??s', 'Ferrabrás'],
  ['C??rrego', 'Córrego'],
  ['Orqu??dea', 'Orquídea'],
  ['Fi??rio', 'Fiório'],
  ['Theodorico', 'Theodorico'],
  ['Ferra??o', 'Ferrão'],
  ['Esperan??a', 'Esperança'],
  ['Ara??aris', 'Araçaris'],
  ['Oct??vio', 'Octávio'],
  ['Alto??', 'Altoé'],
  ['An??pio', 'Anépio'],
  ['Bocai??va', 'Bocaiúva'],
  ['C??ndido', 'Cândido'],
  ['Ic??', 'Icó'],
  ['Iju??', 'Ijuí'],
  ['Mar??o', 'Março'],
  ['L??o', 'Léo'],
  ['??ngelo', 'Ângelo'],
  ['Trist??o', 'Tristão'],
  ['Goi??nia', 'Goiânia'],
  ['Canad??', 'Canadá'],
  ['L??cio', 'Lúcio'],
  ['An??rio', 'Anário'],
  ['Elesb??o', 'Elesbão'],
  ['Bar??o', 'Barão'],
  ['F??bio', 'Fábio'],
  ['Jacarand??', 'Jacarandá'],
  ['T??rcio', 'Tércio'],
  ['Corr??a', 'Corrêa'],
  ['Flor??ncio', 'Florêncio'],
  ['Guimar??es', 'Guimarães'],
  ['Rinc??o', 'Rincão'],
  ['H??lvio', 'Hélvio'],
  ['Irm??os', 'Irmãos'],
  ['Irm??s', 'Irmãs'],
  ['Uni??o', 'União'],
  ['Sim??o', 'Simão'],
  ['F??lix', 'Félix'],
  ['Gr??pias', 'Gráupias'],
  ['J??ronimo', 'Jerônimo'],
  ['Euz??bio', 'Euzébio'],
  ['Nicolau', 'Nicolau'],
  ['Vit??rio', 'Vitório'],
  ['Mac??do', 'Macêdo'],
  ['Caf??', 'Café'],
  ['Ge??rgia', 'Geórgia'],
  ['Timbu??', 'Timbuí'],
  ['Parad??o', 'Paradão'],
  ['pr??dio', 'prédio'],
  ['piso', 'piso'],
  ['Brand??o', 'Brandão'],
  ['Ot??lia', 'Otília'],
  ['L??der', 'Líder'],
  ['Jap??o', 'Japão'],
  ['Rebou??as', 'Rebouças']
]

tables = ['addresses', 'cities', 'banks', 'person_types', 'provider_service_types', 'orientation_manuals', 'users', 'services']
columns_map = {
  'addresses' => ['district', 'address', 'complement'],
  'cities' => ['name'],
  'banks' => ['name'],
  'person_types' => ['name'],
  'provider_service_types' => ['name'],
  'orientation_manuals' => ['name', 'description'],
  'users' => ['name', 'company_name', 'fantasy_name'],
  'services' => ['name', 'description']
}

total_fixed = 0

tables.each do |table|
  next unless conn.table_exists?(table)
  columns = columns_map[table] || []
  
  columns.each do |col|
    next unless conn.column_exists?(table, col)
    
    replacements.each do |wrong, correct|
      begin
        result = conn.execute("UPDATE #{table} SET #{col} = REPLACE(#{col}, '#{wrong}', '#{correct}') WHERE #{col} LIKE '%#{wrong}%'")
        affected = conn.raw_connection.affected_rows rescue 0
        if affected > 0
          puts "  ✓ #{table}.#{col}: '#{wrong}' → '#{correct}' (#{affected} registros)"
          total_fixed += affected
        end
      rescue => e
        # Ignorar erros de replace
      end
    end
  end
end

puts "\n" + "=" * 70
puts "CORREÇÃO CONCLUÍDA!"
puts "Total de substituições: #{total_fixed}"
puts "=" * 70
