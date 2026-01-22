os = OrderService.find(66)
puts 'OS #66:'
puts "  Cliente: #{os.client.name}"
puts "  Status OS: #{os.order_service_status.name}"
puts ''
puts 'Propostas:'
os.order_service_proposals.each do |p|
  puts "  Proposta ##{p.id} - Status ID: #{p.order_service_proposal_status_id} - Status: #{p.order_service_proposal_status&.name || 'NULL'}"
end
