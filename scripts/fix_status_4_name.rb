ActiveRecord::Base.connection.execute("
  UPDATE order_service_statuses 
  SET name = 'Aguardando avaliação de proposta'
  WHERE id = 4
")

puts "✅ Nome do status corrigido"
puts "Status ID 4: #{OrderServiceStatus.find(4).name}"
