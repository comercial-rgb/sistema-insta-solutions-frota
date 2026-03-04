#!/usr/bin/env ruby
# Fix OS 210 (42210) - transition from Aprovada to Nota Fiscal Inserida
# The supplier inserted invoice 837 but the system didn't transition the status

os = OrderService.unscoped.find(210)
proposal = OrderServiceProposal.unscoped.find(220)

puts "BEFORE:"
puts "  OS #{os.id} (#{os.code}): status=#{os.order_service_status_id} (#{os.order_service_status&.name})"
puts "  Proposal #{proposal.id}: status=#{proposal.order_service_proposal_status_id} (#{proposal.order_service_proposal_status&.name})"
puts "  Invoice count: #{proposal.order_service_invoices.count}"

# Only fix if currently in Aprovada
if os.order_service_status_id == OrderServiceStatus::APROVADA_ID && 
   proposal.order_service_proposal_status_id == OrderServiceProposalStatus::APROVADA_ID &&
   proposal.order_service_invoices.count > 0

  # Create audit entries
  admin_user = User.find(1)  # Admin Geral
  
  # Audit for OS status change
  os.audits.create!(
    user: admin_user,
    action: 'update',
    audited_changes: {
      "order_service_status" => ["Aprovada", "Nota fiscal inserida"],
      "order_service_status_id" => [OrderServiceStatus::APROVADA_ID, OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID]
    },
    comment: "Correção manual: fornecedor inseriu NF mas status não transitou automaticamente"
  )
  
  # Audit for proposal status change
  proposal.audits.create!(
    user: admin_user,
    action: 'update',
    audited_changes: {
      "order_service_proposal_status" => ["Aprovada", "Notas fiscais inseridas"],
      "order_service_proposal_status_id" => [OrderServiceProposalStatus::APROVADA_ID, OrderServiceProposalStatus::NOTAS_INSERIDAS_ID]
    },
    comment: "Correção manual: fornecedor inseriu NF mas status não transitou automaticamente"
  )
  
  # Update statuses
  os.update_columns(order_service_status_id: OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID)
  proposal.update_columns(order_service_proposal_status_id: OrderServiceProposalStatus::NOTAS_INSERIDAS_ID)
  
  # Reload and verify
  os.reload
  proposal.reload
  
  puts "\nAFTER:"
  puts "  OS #{os.id} (#{os.code}): status=#{os.order_service_status_id} (#{os.order_service_status&.name})"
  puts "  Proposal #{proposal.id}: status=#{proposal.order_service_proposal_status_id} (#{proposal.order_service_proposal_status&.name})"
  puts "\nFIX APPLIED SUCCESSFULLY!"
else
  puts "\nSKIPPED: Conditions not met (OS status=#{os.order_service_status_id}, Proposal status=#{proposal.order_service_proposal_status_id}, Invoices=#{proposal.order_service_invoices.count})"
end
