# -*- coding: utf-8 -*-
# Diagnostico de problemas de codificacao nas OSs 861, 862, 863, 875
os_ids = [861, 862, 863, 875]

os_ids.each do |os_id|
  puts "=" * 60
  os = OrderService.find_by(id: os_id)
  puts "OS #{os&.code} (ID: #{os_id})"
  
  # Check commitment parts
  if os.commitment_parts_id.present?
    puts "  commitment_parts_id: #{os.commitment_parts_id}"
    c = Commitment.find_by(id: os.commitment_parts_id)
    if c
      puts "    commitment_number: #{c.commitment_number.inspect} (enc: #{c.commitment_number.to_s.encoding})"
      begin
        contract = c.contract
        if contract
          puts "    contract.number: #{contract.number.inspect} (enc: #{contract.number.to_s.encoding})"
        end
      rescue => e
        puts "    ❌ contract error: #{e.class}: #{e.message}"
      end
    end
  end
  
  # Check commitment services
  if os.commitment_services_id.present?
    puts "  commitment_services_id: #{os.commitment_services_id}"
    c = Commitment.find_by(id: os.commitment_services_id)
    if c
      puts "    commitment_number: #{c.commitment_number.inspect} (enc: #{c.commitment_number.to_s.encoding})"
      begin
        contract = c.contract
        if contract
          puts "    contract.number: #{contract.number.inspect} (enc: #{contract.number.to_s.encoding})"
        end
      rescue => e
        puts "    ❌ contract error: #{e.class}: #{e.message}"
      end
    end
  end
  
  # Check invoice numbers
  proposal = os.approved_proposal
  if proposal
    proposal.order_service_invoices.each do |inv|
      puts "  Invoice #{inv.id}: number=#{inv.number.inspect} (enc: #{inv.number.to_s.encoding})"
    end
  end
  
  # Try building the full payload step by step
  puts "\n  Testing WebhookFinanceService..."
  svc = WebhookFinanceService.new(os_id)
  
  # Check if the error is in get_authorization_date (YAML parsing)
  begin
    date = svc.send(:get_authorization_date)
    puts "  ✅ get_authorization_date: #{date}"
  rescue => e
    puts "  ❌ get_authorization_date: #{e.class}: #{e.message}"
  end
  
  # Check get_tipo
  begin
    tipo = svc.send(:get_tipo)
    puts "  ✅ get_tipo: #{tipo}"
  rescue => e
    puts "  ❌ get_tipo: #{e.class}: #{e.message}"
  end
  
  # Check get_provider_name
  begin
    name = svc.send(:get_provider_name, proposal)
    puts "  ✅ get_provider_name: #{name}"
  rescue => e
    puts "  ❌ get_provider_name: #{e.class}: #{e.message}"
  end
  
  # Check get_invoice_numbers_by_type
  begin
    inv_pecas = svc.send(:get_invoice_numbers_by_type, proposal, 1)
    puts "  ✅ invoice pecas: #{inv_pecas}"
  rescue => e
    puts "  ❌ invoice pecas: #{e.class}: #{e.message}"
  end
  
  begin
    inv_servicos = svc.send(:get_invoice_numbers_by_type, proposal, 2)
    puts "  ✅ invoice servicos: #{inv_servicos}"
  rescue => e
    puts "  ❌ invoice servicos: #{e.class}: #{e.message}"
  end
  
  # Check contract/commitment methods
  begin
    cn = svc.send(:get_contract_number)
    puts "  ✅ get_contract_number: #{cn}"
  rescue => e
    puts "  ❌ get_contract_number: #{e.class}: #{e.message}"
  end
  
  begin
    cc_parts = svc.send(:get_commitment_contract, 'parts')
    puts "  ✅ commitment_contract parts: #{cc_parts}"
  rescue => e
    puts "  ❌ commitment_contract parts: #{e.class}: #{e.message}"
  end
  
  begin
    cn_parts = svc.send(:get_commitment_number, 'parts')
    puts "  ✅ commitment_number parts: #{cn_parts}"
  rescue => e
    puts "  ❌ commitment_number parts: #{e.class}: #{e.message}"
  end
  
  begin
    cc_svc = svc.send(:get_commitment_contract, 'services')
    puts "  ✅ commitment_contract services: #{cc_svc}"
  rescue => e
    puts "  ❌ commitment_contract services: #{e.class}: #{e.message}"
  end
  
  begin
    cn_svc = svc.send(:get_commitment_number, 'services')
    puts "  ✅ commitment_number services: #{cn_svc}"
  rescue => e
    puts "  ❌ commitment_number services: #{e.class}: #{e.message}"
  end
  
  # Try full payload
  begin
    p = svc.send(:payload)
    puts "  ✅ payload built OK"
    p.to_json
    puts "  ✅ payload.to_json OK"
  rescue => e
    puts "  ❌ payload: #{e.class}: #{e.message}"
    puts "    #{e.backtrace.first(3).join("\n    ")}"
  end
end
