#!/usr/bin/env python3
"""
Patch: Limita emails de falha webhook para no máximo 2 destinatários
e adiciona deduplicação no job para evitar notificações repetidas.
"""

FILE_MAILER = "app/mailers/notification_mailer.rb"
FILE_JOB = "app/jobs/send_authorized_os_webhook_job.rb"

# ===== PATCH 1: Mailer - limitar a 2 emails =====
print("1. Patching notification_mailer.rb...")

with open(FILE_MAILER, "r") as f:
    content = f.read()

OLD_MAILER = """        def webhook_failure_alert(order_service, error_message)
                @order_service = order_service
                @error_message = error_message
                @os_code = order_service&.code || 'N/A'
                @client_name = order_service&.client&.fantasy_name || order_service&.client&.social_name || 'N/A'

                # Envia para todos os admins aprovados
                admin_emails = User.admin.where(user_status_id: UserStatus::APROVADO_ID).pluck(:email).compact.select { |e| CustomHelper.address_valid?(e) }

                if admin_emails.any?
                        mail(
                                to: admin_emails,
                                subject: "[ALERTA] Falha no envio da OS #{@os_code} ao Portal Financeiro"
                        )
                end
        end"""

NEW_MAILER = """        def webhook_failure_alert(order_service, error_message)
                @order_service = order_service
                @error_message = error_message
                @os_code = order_service&.code || 'N/A'
                @client_name = order_service&.client&.fantasy_name || order_service&.client&.social_name || 'N/A'

                # Envia para no máximo 2 admins principais (os demais veem a notificação in-app)
                admin_emails = User.admin
                        .where(user_status_id: UserStatus::APROVADO_ID)
                        .order(:id)
                        .limit(2)
                        .pluck(:email)
                        .compact
                        .select { |e| CustomHelper.address_valid?(e) }

                if admin_emails.any?
                        mail(
                                to: admin_emails.first,
                                cc: admin_emails[1],
                                subject: "[ALERTA] Falha no envio da OS #{@os_code} ao Portal Financeiro"
                        )
                end
        end"""

if OLD_MAILER in content:
    content = content.replace(OLD_MAILER, NEW_MAILER, 1)
    with open(FILE_MAILER, "w") as f:
        f.write(content)
    print("  OK: Mailer atualizado - limitado a 2 emails (to + cc)")
else:
    print("  WARN: Match exato não encontrado, tentando alternativa...")
    # Try with the method signature
    if "def webhook_failure_alert" in content:
        import re
        pattern = r'(\s+def webhook_failure_alert.*?)((?=\s+def )|end\s*$)'
        # Simpler: replace between method def and end
        start = content.find("        def webhook_failure_alert")
        end_marker = content.find("\nend", start)
        if start >= 0 and end_marker >= 0:
            content = content[:start] + NEW_MAILER + "\n\n" + content[end_marker:]
            with open(FILE_MAILER, "w") as f:
                f.write(content)
            print("  OK: Mailer atualizado via boundary match")
        else:
            print("  ERRO: Não conseguiu delimitar o método!")
            exit(1)
    else:
        print("  ERRO: Método webhook_failure_alert não encontrado!")
        exit(1)


# ===== PATCH 2: Job - deduplicação =====
print("2. Patching send_authorized_os_webhook_job.rb...")

NEW_JOB = """# Job para enviar webhook de OS autorizada de forma assíncrona
class SendAuthorizedOsWebhookJob < ApplicationJob
  queue_as :default

  # Retry com backoff exponencial em caso de falha (3 tentativas)
  retry_on StandardError, wait: :exponentially_longer, attempts: 3 do |job, error|
    # Executado APENAS quando TODAS as tentativas falharam
    order_service_id = job.arguments.first
    notify_admins_webhook_failure(order_service_id, error)
  end

  def perform(order_service_id)
    result = WebhookFinanceService.send_authorized_os(order_service_id)

    unless result[:success]
      Rails.logger.warn "[SendAuthorizedOsWebhookJob] Falha ao enviar webhook para OS #{order_service_id}: #{result[:error]}"
      # Lança exceção para acionar o retry automático
      raise "Webhook falhou para OS #{order_service_id}: #{result[:error]}"
    end
  end

  private

  def self.notify_admins_webhook_failure(order_service_id, error)
    os = OrderService.find_by(id: order_service_id)
    os_code = os&.code || "ID #{order_service_id}"
    client_name = os&.client&.fantasy_name || os&.client&.social_name || 'N/A'
    error_msg = error&.message.to_s

    Rails.logger.error "[SendAuthorizedOsWebhookJob] FALHA DEFINITIVA - OS #{os_code}: #{error_msg}"

    # Deduplicação: verifica se já existe notificação recente (últimas 2h) para esta OS
    recent_notification = Notification.where(profile_id: Profile::ADMIN_ID)
      .where("title LIKE ?", "%Portal Financeiro%")
      .where("message LIKE ?", "%#{os_code}%")
      .where("created_at > ?", 2.hours.ago)
      .exists?

    if recent_notification
      Rails.logger.info "[SendAuthorizedOsWebhookJob] Notificação já existe para OS #{os_code} (últimas 2h). Ignorando duplicata."
      return
    end

    # 1) Notificação in-app para todos os admins
    begin
      Notification.create!(
        profile_id: Profile::ADMIN_ID,
        send_all: true,
        title: "Falha no envio ao Portal Financeiro",
        message: "A OS <strong>#{os_code}</strong> do cliente <strong>#{client_name}</strong> " \\
                 "não foi enviada ao Portal Financeiro após 3 tentativas.<br>" \\
                 "<strong>Erro:</strong> #{error_msg}<br>" \\
                 "<em>Verifique o Portal Financeiro ou tente reenviar manualmente.</em>"
      )
    rescue => e
      Rails.logger.error "[SendAuthorizedOsWebhookJob] Erro ao criar notificação: #{e.message}"
    end

    # 2) Email consolidado (máximo 1 email - to + cc)
    begin
      NotificationMailer.webhook_failure_alert(os, error_msg).deliver_later
    rescue => e
      Rails.logger.error "[SendAuthorizedOsWebhookJob] Erro ao enviar email: #{e.message}"
    end
  end
end
"""

with open(FILE_JOB, "w") as f:
    f.write(NEW_JOB)
print("  OK: Job atualizado com deduplicação de notificações")

print("\nPatch concluído!")
