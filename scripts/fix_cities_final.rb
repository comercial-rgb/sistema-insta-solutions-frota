# Verificação e correção final das cidades
conn = ActiveRecord::Base.connection

puts "=" * 60
puts "VERIFICANDO CIDADES COM PROBLEMAS DE ENCODING"
puts "=" * 60

# Buscar cidades com caracteres estranhos
problematic_chars = ['á', 'ã', 'â', 'ô', 'ó', 'í', 'ú', 'é', 'ê', 'ç']
good_chars = ['á', 'ã', 'â', 'ô', 'ó', 'í', 'ú', 'é', 'ê', 'ç']

# Verificar algumas cidades específicas
puts "\nCidades que deveriam ter 'Açailândia' (MA):"
City.where("name LIKE '%çã%' OR name LIKE '%Aça%'").each { |c| puts "  ID #{c.id}: #{c.name}" }

# Correções manuais específicas
manual_fixes = {
  'Açãilândia' => 'Açailândia',
  'Açãi' => 'Açai',
  'çãi' => 'çai'
}

puts "\nAplicando correções manuais:"
manual_fixes.each do |wrong, correct|
  begin
    sql = "UPDATE cities SET name = REPLACE(name, #{conn.quote(wrong)}, #{conn.quote(correct)}) WHERE name LIKE #{conn.quote("%#{wrong}%")}"
    conn.execute(sql)
    affected = conn.raw_connection.affected_rows rescue 0
    puts "  '#{wrong}' → '#{correct}': #{affected} registros" if affected > 0
  rescue => e
    puts "  Erro: #{e.message}"
  end
end

# Verificar se ainda há problemas
puts "\nVerificando cidades começando com Aç:"
City.where("name LIKE 'Aç%'").limit(20).each { |c| puts "  #{c.name}" }

puts "\nVerificando cidades com 'João':"
City.where("name LIKE '%João%'").limit(10).each { |c| puts "  #{c.name}" }
