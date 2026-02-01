# Últimas correções das cidades
conn = ActiveRecord::Base.connection

puts "CORREÇÕES FINAIS DAS CIDADES"
puts "=" * 50

corrections = [
  ['Abaçra', 'Abaíra'],
  ['Abaetá', 'Abaeté'],
  ['Abatiç', 'Abatiá'],
  ['çra', 'íra'],
  ['etá', 'eté'],
  ['tiç', 'tiá'],
  ['açra', 'aíra'],
  ['iça', 'iça'],  # já certo
  ['uça', 'uça'],  # já certo
  ['açu', 'açu'],  # já certo
]

total = 0
corrections.each do |wrong, correct|
  next if wrong == correct
  begin
    sql = "UPDATE cities SET name = REPLACE(name, #{conn.quote(wrong)}, #{conn.quote(correct)}) WHERE name LIKE #{conn.quote("%#{wrong}%")}"
    conn.execute(sql)
    affected = conn.raw_connection.affected_rows rescue 0
    if affected > 0
      puts "  '#{wrong}' → '#{correct}': #{affected}"
      total += affected
    end
  rescue => e
    puts "  Erro: #{e.message}"
  end
end

puts "\nTotal: #{total}"

# Verificar
puts "\nAmostra final:"
City.limit(15).each { |c| puts "  #{c.name}" }
