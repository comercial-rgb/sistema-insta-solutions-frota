#!/usr/bin/env ruby
# Script to check the status of 5 OS records - try both ID and code
ids = [42130, 42137, 42553, 42577, 42210]

# First check by ID
puts "--- Searching by ID ---"
ids.each do |id|
  os = OrderService.unscoped.find_by(id: id)
  if os
    puts "=== OS id=#{id} (code: #{os.code}) ==="
    puts "  Status ID: #{os.order_service_status_id} (#{os.order_service_status&.name})"
    puts "  Type: #{os.order_service_type&.name}"
    puts "  Provider: #{os.provider&.name} (id: #{os.provider_id})"
    puts "  Created: #{os.created_at}"
    puts "  Updated: #{os.updated_at}"
    
    proposals = os.order_service_proposals
    puts "  Proposals (#{proposals.count}):"
    proposals.each do |p|
      puts "    Prop #{p.id}: status=#{p.order_service_proposal_status_id} (#{p.order_service_proposal_status&.name}), complement=#{p.is_complement}, provider_id=#{p.provider_id} (#{User.unscoped.find_by(id: p.provider_id)&.name})"
      
      # Check invoices on proposal
      if p.respond_to?(:order_service_invoices)
        invs = p.order_service_invoices
        puts "      Invoices: #{invs.count}"
        invs.each do |inv|
          cols = inv.attributes.keys
          puts "      Inv #{inv.id}: #{inv.attributes.slice(*cols).inspect}"
        end
      end
    end
    
    # Check invoices on OS
    if os.respond_to?(:order_service_invoices)
      invs = os.order_service_invoices
      puts "  OS Direct Invoices: #{invs.count}"
    end
  else
    puts "=== ID #{id}: NOT FOUND ==="
  end
  puts ""
end

# Check what code format looks like
puts "--- Sample codes ---"
OrderService.unscoped.order(id: :desc).limit(5).each do |os|
  puts "  id=#{os.id}, code=#{os.code}"
end

# Also check max id
puts "Max ID: #{OrderService.unscoped.maximum(:id)}"
puts "Total OS: #{OrderService.unscoped.count}"
