puts "IDs de Tipos de OS no Banco:"
puts "=" * 50
OrderServiceType.order(:id).each do |t|
  puts "ID: #{t.id} - #{t.name}"
end
