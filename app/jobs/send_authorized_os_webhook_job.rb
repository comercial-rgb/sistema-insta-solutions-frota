# Job para enviar webhook de OS autorizada de forma assíncrona
class SendAuthorizedOsWebhookJob < ApplicationJob
  queue_as :default

  # Retry com backoff exponencial em caso de falha (3 tentativas)
  retry_on StandardError, wait: :exponentially_longer, attempts: 3 do |job, error|
    # Executado quando TODAS as tentativas falharam
    order_service_id = job.arguments.first
    mark_webhook_log_failed(order_service_id, error)
    notify_admins_webhook_failure(order_service_id, error)
  end

  def perform(order_service_id, resend: false)
    # Garante que o WebhookLog existe antes da primeira tentativa
    ensure_webhook_log(order_service_id)

    result = WebhookFinanceService.send_authorized_os(order_service_id, resend: resend)

    unless result[:success]
      Rails.logger.warn "[SendAuthorizedOsWebhookJob] Falha ao enviar webhook para OS #{order_service_id}: #{result[:error]}"
      # Lança exceção para acionar o retry automático
      raise "Webhook falhou para OS #{order_service_id}: #{result[:error]}"
    end
  end

  private

  def ensure_webhook_log(order_service_id)
    WebhookLog.find_or_create_by(order_service_id: order_service_id) do |log|
      log.status = WebhookLog::PENDING
      log.attempts = 0
    end
  rescue => e
    Rails.logger.error "[SendAuthorizedOsWebhookJob] Erro ao criar WebhookLog: #{e.message}"
  end

  def self.mark_webhook_log_failed(order_service_id, error)
    log = WebhookLog.find_by(order_service_id: order_service_id)
    return unless log
    log.update(
      status: WebhookLog::FAILED,
      last_error: error&.message.to_s.truncate(255),
      last_attempt_at: Time.current
    )
  rescue => e
    Rails.logger.error "[SendAuthorizedOsWebhookJob] Erro ao atualizar WebhookLog: #{e.message}"
  end

  def self.notify_admins_webhook_failure(order_service_id, error)
    os = OrderService.find_by(id: order_service_id)
    os_code = os&.code || "ID #{order_service_id}"
    client_name = os&.client&.fantasy_name || os&.client&.social_name || 'N/A'
    error_msg = error&.message.to_s

    Rails.logger.error "[SendAuthorizedOsWebhookJob] FALHA DEFINITIVA - OS #{os_code}: #{error_msg}"

    # 1) Notificação in-app para todos os admins
    begin
      notification = Notification.create!(
        profile_id: Profile::ADMIN_ID,
        send_all: true,
        title: "Falha no envio ao Portal Financeiro",
        message: "A OS <strong>#{os_code}</strong> do cliente <strong>#{client_name}</strong> " \
                 "não foi enviada ao Portal Financeiro após 3 tentativas.<br>" \
                 "<strong>Erro:</strong> #{error_msg}<br>" \
                 "<em>Verifique o Portal Financeiro ou tente reenviar manualmente.</em>"
      )
      Rails.logger.info "[SendAuthorizedOsWebhookJob] Notificação #{notification.id} criada para admins"
    rescue => e
      Rails.logger.error "[SendAuthorizedOsWebhookJob] Erro ao criar notificação: #{e.message}"
    end

    # 2) Email para admins
    begin
      NotificationMailer.webhook_failure_alert(os, error_msg).deliver_later
    rescue => e
      Rails.logger.error "[SendAuthorizedOsWebhookJob] Erro ao enviar email: #{e.message}"
    end
  end
end
