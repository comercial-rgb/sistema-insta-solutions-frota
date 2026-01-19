namespace :complement do
  desc "Converter provider_service_temps existentes em order_service_proposal_items para complementos"
  task fix_items: :environment do
    puts "Buscando complementos com provider_service_temps..."
    
    complements = OrderServiceProposal.where(is_complement: true)
      .includes(:provider_service_temps, :order_service_proposal_items)
    
    puts "Encontrados #{complements.count} complementos"
    
    fixed_count = 0
    complements.each do |complement|
      # Só converter se tem provider_service_temps mas não tem order_service_proposal_items
      if complement.provider_service_temps.any? && complement.order_service_proposal_items.empty?
        puts "Convertendo complemento ##{complement.id} (#{complement.code})..."
        
        complement.provider_service_temps.each do |pst|
          complement.order_service_proposal_items.create!(
            service_id: pst.service_id,
            quantity: pst.quantity,
            unity_value: pst.price,
            discount: pst.discount,
            total_value: pst.total_value,
            total_value_without_discount: (pst.price.to_f * pst.quantity.to_i),
            brand: pst.brand,
            guarantee: pst.warranty_period,
            observation: pst.observation,
            is_complement: true
          )
        end
        
        # Atualizar totais
        OrderServiceProposal.update_total_values(complement)
        fixed_count += 1
        puts "  ✓ Convertido #{complement.provider_service_temps.count} itens"
      end
    end
    
    puts "\n✓ Processo concluído! #{fixed_count} complementos corrigidos."
  end
end
