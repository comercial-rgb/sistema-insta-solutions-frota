# Script para diagnosticar o erro de encoding nas OSs 861, 862, 863, 875
# Uso: RAILS_ENV=production bundle exec rails runner scripts/debug_encoding.rb

os_ids = [861, 862, 863, 875]

os_ids.each do |os_id|
  puts "=" * 60
  puts "OS ID: #{os_id}"
  os = OrderService.find_by(id: os_id)
  unless os
    puts "  NAO ENCONTRADA"
    next
  end
  
  puts "  Code: #{os.code}"
  puts "  Status ID: #{os.order_service_status_id}"
  
  # Check encoding of details field
  if os.details.present?
    puts "  Details encoding: #{os.details.encoding}"
    puts "  Details valid?: #{os.details.valid_encoding?}"
    puts "  Details preview: #{os.details.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')[0..100]}"
  else
    puts "  Details: (empty)"
  end
  
  # Check client
  client = os.client
  if client
    puts "  Client fantasy_name encoding: #{client.fantasy_name.to_s.encoding}" if client.fantasy_name
    puts "  Client social_name encoding: #{client.social_name.to_s.encoding}" if client.social_name
  end
  
  # Check provider via approved_proposal
  proposal = os.approved_proposal
  if proposal
    provider = proposal.provider
    if provider
      puts "  Provider fantasy_name encoding: #{provider.fantasy_name.to_s.encoding}" if provider.fantasy_name
      puts "  Provider social_name encoding: #{provider.social_name.to_s.encoding}" if provider.social_name
    end
  end
  
  # Check vehicle
  vehicle = os.vehicle
  if vehicle
    puts "  Vehicle brand encoding: #{vehicle.brand.to_s.encoding}" if vehicle.brand
    puts "  Vehicle model encoding: #{vehicle.model.to_s.encoding}" if vehicle.model
  end
  
  # Check sub_unit
  sub_unit = os.sub_unit
  if sub_unit
    puts "  SubUnit name encoding: #{sub_unit.name.to_s.encoding}" if sub_unit.name
  end
  
  # Check order_service_type
  ost = os.order_service_type
  if ost
    puts "  OrderServiceType name encoding: #{ost.name.to_s.encoding}" if ost.name
  end
  
  # Check cost_center
  cc = os.cost_center
  if cc
    puts "  CostCenter name encoding: #{cc.name.to_s.encoding}" if cc.name
  end
  
  # Try building payload manually to find the issue
  begin
    payload = {
      codigo: os.code.to_s,
      clienteNomeFantasia: (os.client&.fantasy_name || os.client&.social_name).to_s,
      fornecedorNomeFantasia: (proposal&.provider&.fantasy_name || proposal&.provider&.social_name).to_s,
      tipoServicoSolicitado: os.order_service_type&.name.to_s,
      centroCusto: os.cost_center&.name.to_s,
      subunidade: os.sub_unit&.name.to_s,
      placa: os.vehicle&.board.to_s,
      veiculo: [os.vehicle&.brand, os.vehicle&.model, os.vehicle&.year].compact.join(' '),
      observacoes: os.details.to_s
    }
    
    # Try each field
    payload.each do |key, val|
      begin
        val.to_json
      rescue => e
        puts "  ❌ CAMPO COM PROBLEMA: #{key} (encoding: #{val.encoding}, valid: #{val.valid_encoding?})"
        puts "     Valor: #{val.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')[0..50]}"
      end
    end
    
    # Try full payload to_json
    payload.to_json
    puts "  ✅ Payload JSON OK"
  rescue => e
    puts "  ❌ Erro no payload: #{e.message}"
  end
end
