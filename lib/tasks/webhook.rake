namespace :webhook do
  desc "Popula webhook_logs com OS autorizadas/ag. pagamento/pagas que não têm log de sucesso"
  task seed_missing: :environment do
    # OS que passaram por status Autorizada (5 ou 7) e depois avançaram
    # mas não têm registro de webhook_log com sucesso
    advanced_statuses = [
      OrderServiceStatus::AUTORIZADA_ID,
      OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID,
      OrderServiceStatus::PAGA_ID
    ]

    # Tenta incluir NEW_AUTORIZADA_ID se definido
    begin
      advanced_statuses << OrderServiceStatus::NEW_AUTORIZADA_ID
    rescue
      # ignora se não existir
    end

    advanced_statuses.uniq!

    os_without_log = OrderService
      .where(order_service_status_id: advanced_statuses)
      .where.not(id: WebhookLog.select(:order_service_id))

    total = os_without_log.count
    puts "Encontradas #{total} OS sem registro de webhook..."

    created = 0
    os_without_log.find_each do |os|
      # Verifica se tem proposta aprovada (pré-requisito do webhook)
      next unless os.approved_proposal

      WebhookLog.create!(
        order_service_id: os.id,
        status: WebhookLog::FAILED,
        attempts: 0,
        last_error: "Histórico: OS sem registro de webhook (anterior à implementação do tracking)",
        last_attempt_at: nil
      )
      created += 1
    end

    puts "Criados #{created} registros de webhook_log para reprocessamento."
    puts "Acesse Portal Financeiro > Gerenciar Webhooks para reenviar."
  end

  desc "Reprocessa todas as OS com webhook falho"
  task resend_failed: :environment do
    failed = WebhookLog.failed
    count = failed.count
    puts "Reenviando #{count} OS com webhook falho..."

    failed.each do |log|
      log.update(status: WebhookLog::PENDING, last_error: nil, attempts: 0)
      SendAuthorizedOsWebhookJob.perform_later(log.order_service_id, force: true)
      print "."
    end

    puts "\n#{count} OS enfileiradas para reenvio."
  end
end
