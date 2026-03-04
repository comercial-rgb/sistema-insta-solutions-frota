#!/usr/bin/env ruby
# Script to check the status of 5 OS records
codes = ["42130", "42137", "42553", "42577", "42210"]
codes.each do |code|
  os = OrderService.unscoped.find_by(code: code)
  if os
    puts "=== OS #{code} (id: #{os.id}) ==="
    puts "  Status ID: #{os.order_service_status_id} (#{os.order_service_status&.name})"
    puts "  Type: #{os.order_service_type&.name}"
    puts "  Provider: #{os.provider&.name} (id: #{os.provider_id})"
    puts "  Created: #{os.created_at}"
    puts "  Updated: #{os.updated_at}"
    
    proposals = os.order_service_proposals
    puts "  Proposals (#{proposals.count}):"
    proposals.each do |p|
      puts "    Prop #{p.id}: status=#{p.order_service_proposal_status_id} (#{p.order_service_proposal_status&.name}), complement=#{p.is_complement}, provider=#{p.provider_id}"
      
      # Check invoices on proposal
      if p.respond_to?(:order_service_invoices)
        invs = p.order_service_invoices
        puts "    Invoices on proposal: #{invs.count}"
        invs.each do |inv|
          puts "      Inv #{inv.id}: type_id=#{inv.order_service_invoice_type_id}, number=#{inv.try(:invoice_number) || inv.try(:number) || 'N/A'}, value=#{inv.try(:value) || inv.try(:total_value) || 'N/A'}"
        end
      end
    end
    
    # Check invoices on OS itself
    if os.respond_to?(:order_service_invoices)
      invs = os.order_service_invoices
      puts "  OS Invoices: #{invs.count}"
      invs.each do |inv|
        puts "    Inv #{inv.id}: type_id=#{inv.order_service_invoice_type_id}, number=#{inv.try(:invoice_number) || inv.try(:number) || 'N/A'}"
      end
    end
  else
    puts "=== OS #{code}: NOT FOUND ==="
  end
  puts ""
end
