namespace :contracts do
  desc "Verificar contratos prestes a expirar e enviar notificações"
  task check_expiration: :environment do
    puts "Verificando contratos prestes a expirar..."
    
    # Data limite: contratos que vencem em 1 mês ou menos
    target_date = 1.month.from_now.to_date
    today = Date.today
    
    # Buscar contratos que ainda não foram notificados e que vencem em até 1 mês
    contracts_expiring = Contract.where(active: true)
                                 .where(expiration_notified_at: nil)
                                 .where.not(final_date: [nil, ''])
    
    contracts_expiring.find_each do |contract|
      begin
        # Converter a data final para Date (formato esperado: dd/mm/yyyy)
        final_date = parse_date(contract.final_date)
        
        next if final_date.nil?
        
        # Verifica se está a 1 mês ou menos do vencimento e ainda não venceu
        if final_date >= today && final_date <= target_date
          # Calcular dias restantes
          days_remaining = (final_date - today).to_i
          
          # Criar notificação para todos os usuários do cliente
          create_expiration_notification(contract, days_remaining, final_date)
          
          # Marcar como notificado
          contract.update(expiration_notified_at: Time.current)
          
          puts "Notificação criada para contrato ##{contract.id} - #{contract.name} (#{days_remaining} dias restantes)"
        end
      rescue => e
        puts "Erro ao processar contrato ##{contract.id}: #{e.message}"
      end
    end
    
    puts "Verificação de contratos concluída!"
  end
  
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
    
    # Criar notificação para todos os usuários (send_all: true)
    notification = Notification.create!(
      title: title,
      message: message,
      send_all: true,
      profile_id: nil # Enviado para todos os perfis
    )
    
    notification
  end
end
