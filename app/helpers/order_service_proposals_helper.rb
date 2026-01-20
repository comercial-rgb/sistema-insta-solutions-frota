module OrderServiceProposalsHelper
  # Compara o preço atual com as últimas 3 OS do mesmo veículo e mesmo item
  # Retorna: :higher (preço mais alto), :similar (±R$ 10,00), :lower (preço mais baixo), :no_comparison (sem histórico)
  def compare_item_price(current_item, order_service)
    return :no_comparison unless order_service.vehicle_id.present? && current_item.service_id.present?
    
    # Buscar as últimas 3 OS aprovadas do mesmo veículo (exceto a atual)
    last_order_services = OrderService
      .joins(:order_service_proposals)
      .where(vehicle_id: order_service.vehicle_id)
      .where.not(id: order_service.id)
      .where(order_service_proposals: { 
        order_service_proposal_status_id: OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES 
      })
      .where('order_services.created_at < ?', order_service.created_at)
      .order(created_at: :desc)
      .limit(3)
      .distinct
    
    return :no_comparison if last_order_services.empty?
    
    # Buscar itens do mesmo serviço nas propostas aprovadas dessas OS
    historical_prices = OrderServiceProposalItem
      .joins(order_service_proposal: :order_service)
      .where(service_id: current_item.service_id)
      .where(order_service_proposals: { 
        order_service_id: last_order_services.pluck(:id),
        order_service_proposal_status_id: OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES 
      })
      .pluck(:unity_value)
      .map(&:to_f)
      .reject(&:zero?)
    
    return :no_comparison if historical_prices.empty?
    
    # Calcular média dos preços históricos
    avg_historical_price = historical_prices.sum / historical_prices.size
    current_price = current_item.unity_value.to_f
    price_difference = current_price - avg_historical_price
    
    # Margem de R$ 10,00 para considerar similar
    if price_difference > 10.0
      :higher
    elsif price_difference < -10.0
      :lower
    else
      :similar
    end
  end
  
  # Retorna o HTML da seta de comparação de preço
  def price_comparison_arrow(current_item, order_service)
    comparison = compare_item_price(current_item, order_service)
    
    case comparison
    when :higher
      '<span class="price-arrow price-higher" data-bs-toggle="tooltip" title="Preço acima da média das últimas 3 OS (>R$ 10,00)">↑</span>'.html_safe
    when :lower
      '<span class="price-arrow price-lower" data-bs-toggle="tooltip" title="Preço abaixo da média das últimas 3 OS (>R$ 10,00)">↓</span>'.html_safe
    when :similar
      '<span class="price-arrow price-similar" data-bs-toggle="tooltip" title="Preço similar às últimas 3 OS (±R$ 10,00)">—</span>'.html_safe
    else
      ''.html_safe
    end
  end
end
