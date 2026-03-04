#!/usr/bin/env ruby
# Find ALL OS stuck in Aprovada that have invoices inserted
puts "=== OS in Aprovada (status 3) WITH invoices ==="
stuck_os = OrderService.unscoped.where(order_service_status_id: 3)
stuck_count = 0
stuck_os.each do |os|
  os.order_service_proposals.each do |p|
    if p.order_service_invoices.count > 0
      stuck_count += 1
      puts "  OS #{os.id} (code: #{os.code}): proposal=#{p.id}, invoices=#{p.order_service_invoices.count}, proposal_status=#{p.order_service_proposal_status_id} (#{p.order_service_proposal_status&.name})"
      p.order_service_invoices.each do |inv|
        puts "    Invoice #{inv.id}: number=#{inv.number}, value=#{inv.value}, emission=#{inv.emission_date}, created=#{inv.created_at}"
      end
    end
  end
end
puts "Total stuck: #{stuck_count}"

# Also check: proposals in Aprovada (status 3) that have invoices
puts "\n=== Proposals in Aprovada (status 3) with invoices ==="
props = OrderServiceProposal.unscoped.where(order_service_proposal_status_id: 3)
props.each do |p|
  if p.order_service_invoices.count > 0
    os = p.order_service
    puts "  Proposal #{p.id} (OS #{os&.id}, code: #{os&.code}): invoices=#{p.order_service_invoices.count}, os_status=#{os&.order_service_status_id}"
  end
end

# And check: are there other invoice-related issues?
puts "\n=== Proposals in NOTAS_INSERIDAS (status 4) but OS NOT in NOTA_FISCAL_INSERIDA ==="
notas_props = OrderServiceProposal.unscoped.where(order_service_proposal_status_id: 4)
notas_props.each do |p|
  os = p.order_service
  if os && os.order_service_status_id != 4  # OS should be in NOTA_FISCAL_INSERIDA
    puts "  Proposal #{p.id} (OS #{os.id}, code: #{os.code}): os_status=#{os.order_service_status_id} (#{os.order_service_status&.name})"
  end
end
