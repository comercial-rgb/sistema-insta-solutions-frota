#!/usr/bin/env ruby
# Deep investigation of the 5 OS records
os_ids = [130, 137, 553, 577, 210]

os_ids.each do |id|
  os = OrderService.unscoped.find_by(id: id)
  next unless os
  
  puts "=" * 70
  puts "OS id=#{id}, code=#{os.code}"
  puts "  Status: #{os.order_service_status_id} (#{os.order_service_status&.name})"
  puts "  Type: #{os.order_service_type_id} (#{os.order_service_type&.name})"
  puts "  Client: #{os.client_id} (#{User.unscoped.find_by(id: os.client_id)&.name})"
  puts "  Provider: #{os.provider_id} (#{User.unscoped.find_by(id: os.provider_id)&.name})"
  puts "  Created: #{os.created_at}"
  puts "  Updated: #{os.updated_at}"
  puts "  data_inserted_by_provider: #{os.data_inserted_by_provider}"
  puts "  invoice_information: #{os.invoice_information}"
  
  proposals = OrderServiceProposal.unscoped.where(order_service_id: id)
  puts "  Proposals (#{proposals.count}):"
  proposals.each do |p|
    provider = User.unscoped.find_by(id: p.provider_id)
    puts "    Prop id=#{p.id}: status=#{p.order_service_proposal_status_id} (#{p.order_service_proposal_status&.name})"
    puts "      Provider: #{p.provider_id} (#{provider&.name})"
    puts "      is_complement: #{p.is_complement}"
    puts "      pending_manager_authorization: #{p.pending_manager_authorization}"
    puts "      total_parts: #{p.total_parts_value rescue 'N/A'}, total_services: #{p.total_services_value rescue 'N/A'}, total: #{p.total_value rescue 'N/A'}"
    puts "      created: #{p.created_at}, updated: #{p.updated_at}"
    
    # Check for invoice-related columns on proposal
    invoice_cols = p.attributes.keys.select { |k| k.include?('invoice') || k.include?('nota') || k.include?('nf') }
    if invoice_cols.any?
      puts "      Invoice columns: #{invoice_cols.map { |c| "#{c}=#{p[c]}" }.join(', ')}"
    end
    
    # Check for order_service_invoices
    if p.respond_to?(:order_service_invoices)
      invs = p.order_service_invoices
      puts "      Invoices (via relation): #{invs.count}"
      invs.each { |inv| puts "        #{inv.attributes.inspect}" }
    end
    
    # Check attachments
    if p.respond_to?(:attachments)
      atts = p.attachments
      puts "      Attachments: #{atts.count}"
      atts.each do |att|
        puts "        Attachment #{att.id}: #{att.try(:attachment_file_name) || att.try(:filename) || 'N/A'}, created: #{att.created_at}"
      end
    end
  end
  
  # Check audit history
  if os.respond_to?(:audits)
    audits = os.audits.order(created_at: :desc).limit(10)
    puts "  Recent Audits (#{os.audits.count} total):"
    audits.each do |a|
      puts "    #{a.created_at}: action=#{a.action}, user=#{a.user_id}, changes=#{a.audited_changes.inspect[0..200]}"
    end
  end
  
  puts ""
end

# Check OrderServiceInvoice model exists
puts "\n--- Checking Invoice-related models ---"
begin
  puts "OrderServiceInvoice exists: #{defined?(OrderServiceInvoice) ? 'YES' : 'NO'}"
  if defined?(OrderServiceInvoice)
    puts "  Columns: #{OrderServiceInvoice.column_names.join(', ')}"
    puts "  Count: #{OrderServiceInvoice.count}"
  end
rescue => e
  puts "OrderServiceInvoice error: #{e.message}"
end

# Check OrderServiceProposal columns for invoice-related fields
puts "\nOrderServiceProposal columns:"
puts OrderServiceProposal.column_names.select { |c| c.include?('invoice') || c.include?('nota') || c.include?('nf') || c.include?('fiscal') }.join(', ')
puts "\nAll OrderServiceProposal columns:"
puts OrderServiceProposal.column_names.join(', ')
