# Webhooks de gateway (ex.: PagSeguro — ver comentário em config/routes.rb).
# Não exige usuário logado nem CSRF; não persiste payload bruto em log (dados sensíveis).
class PaymentTransactionsController < ApplicationController
  skip_before_action :authenticate_user, only: %i[notify_pix_payment notify_change_payment]
  skip_before_action :verify_authenticity_token, only: %i[notify_pix_payment notify_change_payment]

  def notify_pix_payment
    log_webhook(:pix)
    head :ok
  end

  def notify_change_payment
    log_webhook(:change_payment)
    head :ok
  end

  private

  def log_webhook(kind)
    keys = request.request_parameters.keys.sort.join(",")
    Rails.logger.info(
      "[PaymentTransactions] #{kind} ip=#{request.remote_ip} " \
      "content_type=#{request.content_type} param_keys=#{keys}"
    )
  end
end
