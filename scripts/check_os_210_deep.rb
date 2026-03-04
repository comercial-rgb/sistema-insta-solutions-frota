#!/usr/bin/env ruby
# Deep investigation of OS 210 (42210) - invoice creation and proposal audit

puts "=== OS 210 Details ==="
os = OrderService.unscoped.find(210)
puts "OS status: #{os.order_service_status_id} (#{os.order_service_status&.name})"
puts "OS updated_at: #{os.updated_at}"

proposal = OrderServiceProposal.unscoped.find(220)
puts "\n=== Proposal 220 Details ==="
puts "Proposal status: #{proposal.order_service_proposal_status_id} (#{proposal.order_service_proposal_status&.name})"
puts "Proposal updated_at: #{proposal.updated_at}"
puts "Proposal created_at: #{proposal.created_at}"

puts "\n=== Proposal 220 Audits ==="
audits = Audited::Audit.where(auditable_type: 'OrderServiceProposal', auditable_id: 220).order(:created_at)
puts "Total audits: #{audits.count}"
audits.each do |a|
  puts "  #{a.created_at}: action=#{a.action}, user=#{a.user_id}, changes=#{a.audited_changes.inspect[0..300]}"
end

puts "\n=== Invoice 837 Details ==="
inv = OrderServiceInvoice.find(837)
puts "Invoice id: #{inv.id}"
puts "Invoice proposal_id: #{inv.order_service_proposal_id}"
puts "Invoice type_id: #{inv.order_service_invoice_type_id}"
puts "Invoice number: #{inv.number}"
puts "Invoice value: #{inv.value}"
puts "Invoice emission_date: #{inv.emission_date}"
puts "Invoice created_at: #{inv.created_at}"
puts "Invoice updated_at: #{inv.updated_at}"
if inv.respond_to?(:file) && inv.file.attached?
  puts "Invoice file: #{inv.file.blob.filename}"
else
  puts "Invoice file: NOT ATTACHED"
end

# Check ALL audits around the time the invoice was created (2026-02-11)
puts "\n=== All Audits on 2026-02-11 for OS 210 or Proposal 220 ==="
date_start = Time.parse("2026-02-11 00:00:00")
date_end = Time.parse("2026-02-12 00:00:00")
audits = Audited::Audit.where(created_at: date_start..date_end)
  .where("(auditable_type = 'OrderService' AND auditable_id = 210) OR (auditable_type = 'OrderServiceProposal' AND auditable_id = 220)")
  .order(:created_at)
puts "Found: #{audits.count}"
audits.each do |a|
  puts "  #{a.created_at}: type=#{a.auditable_type}, action=#{a.action}, user=#{a.user_id}, changes=#{a.audited_changes.inspect[0..300]}"
end

# Check if there are any OrderServiceInvoice audits
puts "\n=== OrderServiceInvoice audits ==="
begin
  inv_audits = Audited::Audit.where(auditable_type: 'OrderServiceInvoice', auditable_id: 837)
  puts "Found: #{inv_audits.count}"
  inv_audits.each do |a|
    puts "  #{a.created_at}: action=#{a.action}, user=#{a.user_id}"
  end
rescue => e
  puts "Error: #{e.message}"
end

# Check other OS that successfully transitioned from Aprovada to Nota Fiscal Inserida
puts "\n=== Other OS that reached NOTA_FISCAL_INSERIDA status ==="
nfi_os_ids = Audited::Audit.where(auditable_type: 'OrderService')
  .where("audited_changes LIKE '%order_service_status_id%' AND audited_changes LIKE '%4%'")
  .limit(10)
  .pluck(:auditable_id, :created_at, :audited_changes)
nfi_os_ids.each do |id, ca, changes|
  puts "  OS #{id} at #{ca}: #{changes.inspect[0..200]}"
end

# Check how many OS are in each status
puts "\n=== OS Count by Status ==="
OrderServiceStatus.unscoped.each do |s|
  count = OrderService.unscoped.where(order_service_status_id: s.id).count
  puts "  #{s.id} (#{s.name}): #{count}" if count > 0
end
