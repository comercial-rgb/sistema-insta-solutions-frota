# Job para enviar webhook de OS autorizada de forma assíncrona
class SendAuthorizedOsWebhookJob < ApplicationJob
  queue_as :default

  # Retry com backoff exponencial em caso de falha
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(order_service_id)
    result = WebhookFinanceService.send_authorized_os(order_service_id)
    
    unless result[:success]
      Rails.logger.warn "[SendAuthorizedOsWebhookJob] Falha ao enviar webhook para OS #{order_service_id}: #{result[:error]}"
    end
  end
end
