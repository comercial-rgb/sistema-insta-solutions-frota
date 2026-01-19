class ContractExpirationCheckJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Iniciando verificação de contratos prestes a expirar..."
    
    # Data limite: contratos que vencem em 1 mês ou menos
    target_date = 1.month.from_now.to_date
    today = Date.today
    
    # Buscar contratos ativos que ainda não foram notificados e que têm data final preenchida
    contracts_expiring = Contract.where(active: true)
                                 .where(expiration_notified_at: nil)
                                 .where.not(final_date: [nil, ''])
    
    contracts_notified = 0
    
    contracts_expiring.find_each do |contract|
      begin
        # Converter a data final para Date
        final_date = parse_date(contract.final_date)
        
        next if final_date.nil?
        
        # Verifica se está a 1 mês ou menos do vencimento e ainda não venceu
        if final_date >= today && final_date <= target_date
          # Calcular dias restantes
          days_remaining = (final_date - today).to_i
          
          # Criar notificação
          create_expiration_notification(contract, days_remaining, final_date)
          
          # Marcar como notificado
          contract.update(expiration_notified_at: Time.current)
          
          contracts_notified += 1
          Rails.logger.info "Notificação criada para contrato ##{contract.id} - #{contract.name} (#{days_remaining} dias restantes)"
        end
      rescue => e
        Rails.logger.error "Erro ao processar contrato ##{contract.id}: #{e.message}"
      end
    end
    
    Rails.logger.info "Verificação concluída. #{contracts_notified} contratos notificados."
  end
  
  private
  
  def parse_date(date_string)
    return nil if date_string.blank?
    
    # Tenta diferentes formatos de data
    formats = ['%d/%m/%Y', '%Y-%m-%d', '%d-%m-%Y']
    
    formats.each do |format|
      begin
        return Date.strptime(date_string.strip, format)
      rescue ArgumentError
        next
      end
    end
    
    nil
  end
  
  def create_expiration_notification(contract, days_remaining, final_date)
    # Título e mensagem da notificação
    title = "Contrato #{contract.number} prestes a expirar"
    
    if days_remaining == 0
      message = "O contrato '#{contract.name}' (Nº #{contract.number}) do cliente #{contract.client&.name} expira HOJE!"
    elsif days_remaining == 1
      message = "O contrato '#{contract.name}' (Nº #{contract.number}) do cliente #{contract.client&.name} expira AMANHÃ!"
    else
      message = "O contrato '#{contract.name}' (Nº #{contract.number}) do cliente #{contract.client&.name} expira em #{days_remaining} dias (#{final_date.strftime('%d/%m/%Y')})."
    end
    
    # Criar notificação para todos os usuários
    Notification.create!(
      title: title,
      message: message,
      send_all: true,
      profile_id: nil
    )
  end
end
