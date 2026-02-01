puts 'Status de Propostas no Banco:'
puts '=' * 50
OrderServiceProposalStatus.order(:id).each do |s|
  puts "ID: #{s.id.to_s.rjust(2)} - #{s.name}"
end
