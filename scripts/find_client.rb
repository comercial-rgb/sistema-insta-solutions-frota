# Diagnóstico: listar clientes que contenham "Concei" no nome
puts "Buscando clientes..."
clients = Client.all.select { |c| 
  (c.fantasy_name.to_s =~ /concei/i) || (c.social_name.to_s =~ /concei/i) 
}

if clients.empty?
  puts "Nenhum cliente com 'Concei' encontrado."
  puts "Listando todos os clientes:"
  Client.all.each { |c| puts "  ID #{c.id}: #{c.fantasy_name} / #{c.social_name}" }
else
  clients.each { |c| puts "  ID #{c.id}: #{c.fantasy_name} / #{c.social_name}" }
end
