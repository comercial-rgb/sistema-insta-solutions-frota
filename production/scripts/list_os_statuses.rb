puts "Status de OS no Banco:"
puts "=" * 50
OrderServiceStatus.order(:id).each do |s|
  puts "ID: #{s.id.to_s.rjust(2)} - #{s.name}"
end
