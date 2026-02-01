# Corrigir encoding das cidades - correções específicas
conn = ActiveRecord::Base.connection

puts "=" * 60
puts "CORRIGINDO ENCODING DAS CIDADES"
puts "=" * 60

# Lista de correções de padrões comuns
corrections = [
  # Padrão Sáo -> São
  ["Sáo", "São"],
  ["Joáo", "João"],
  
  # Padrão lándia -> lândia
  ["lándia", "lândia"],
  ["Lándia", "Lândia"],
  
  # Padrão ánia -> ânia  
  ["ánia", "ânia"],
  
  # Padrão ónia -> ônia
  ["ónia", "ônia"],
  
  # Outros padrões
  ["Sapucaá", "Sapucaí"],
  ["Conceiaáo", "Conceição"],
  ["Coraáo", "Coração"],
  ["aáo", "ação"],
  ["eáo", "eção"],
  ["iáo", "ição"],
  ["uáo", "ução"],
  ["Aáu", "Açu"],
  ["aáu", "açu"],
  ["aáa", "açã"],
  ["Aáa", "Açã"],
  ["áa", "ça"],
  ["Máe", "Mãe"],
  ["máe", "mãe"],
  ["ába", "ôba"],
  ["Tráns", "Trans"],
  ["Gráude", "Grande"],
  ["Aá", "Aç"],
  ["aá", "aç"],
  ["Iá", "Iç"],
  ["iá", "iç"],
  ["Uá", "Uç"],
  ["uá", "uç"]
]

total = 0

corrections.each do |wrong, correct|
  begin
    sql = "UPDATE cities SET name = REPLACE(name, #{conn.quote(wrong)}, #{conn.quote(correct)}) WHERE name LIKE #{conn.quote("%#{wrong}%")}"
    conn.execute(sql)
    affected = conn.raw_connection.affected_rows rescue 0
    if affected > 0
      puts "  '#{wrong}' → '#{correct}': #{affected} registros"
      total += affected
    end
  rescue => e
    puts "  Erro em '#{wrong}': #{e.message}"
  end
end

puts "\nTotal de correções: #{total}"

# Verificar amostras
puts "\nAmostra de cidades começando com 'São':"
City.where("name LIKE 'São%'").limit(10).each { |c| puts "  #{c.name}" }

puts "\nAmostra de cidades com 'lândia':"
City.where("name LIKE '%lândia%'").limit(10).each { |c| puts "  #{c.name}" }
