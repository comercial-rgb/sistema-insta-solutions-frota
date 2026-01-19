class Visitors::HomeController < ApplicationController
	skip_before_action :authenticate_user
	skip_before_action :verify_authenticity_token, only: [:receive_update_d4sign]
	
	def index
	end

	def receive_update_d4sign
		# Recebendo notificação de atualização de assinatura
		# Verifica a autenticidade do webhook
		uuid = params[:uuid]
		secret_key = ENV['SECRET_KEY_WEBHOOK_PRODUCTION']
		expected_hmac = request.headers['Content-Hmac'].split('=').last

		computed_hmac = OpenSSL::HMAC.hexdigest('SHA256', secret_key, uuid)

		if computed_hmac == expected_hmac
		  # Processa o webhook conforme necessário
		  contract_signature = ContractSignature.where(uuidDoc: params[:uuid]).first
		  if contract_signature
		    service = Utils::D4Sign::GetDocumentService.new(contract_signature.uuidDoc)
		    transaction = service.call
		    ContractSignature.update_contract_signature(contract_signature)
		  end
		  render json: { status: 'success' }, status: :ok
		else
		  render json: { status: 'unauthorized' }, status: :unauthorized
		end
	end

end