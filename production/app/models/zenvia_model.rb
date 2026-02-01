class ZenviaModel < ApplicationRecord
	
	# Envio do SMS pela gem e as configurações
	def self.send_sms(sms_message, phone_number)
		sms = Zenvia::Sms.new(1234, sms_message, phone_number)
		result = sms.forward
	end

	# Envio do SMS pelo token
	# Exemplo requisição: ZenviaModel.send_sms_by_full_data('teste sms', 5531999999999)
	def self.send_sms_by_full_data(sms_message, phone_number)
		if !sms_message.nil? && !phone_number.nil?
			begin
				schedule_time = Time.now.to_s.split(' ')
				schedule_time = "#{schedule_time[0]}T#{schedule_time[1]}"

				values = "{
	              \"sendSmsRequest\": {
	                \"from\": \"Insta Solutions\",
	                \"to\": \"#{phone_number}\",
	                \"schedule\": \"#{schedule_time}\",
	                \"msg\": \"#{sms_message}\",
	                \"callbackOption\": \"NONE\"
	              }
	            }"

	            # Transformar a conta + senha da API na base64
	            # echo -n conta:senha | base64
				zenvia_token = ''

				logger.info "Zenvia values: #{values}"

				headers = {
					:content_type => 'application/json',
					:authorization => "Basic #{zenvia_token}",
					:accept => 'application/json'
				}

				RestClient.post 'https://api-rest.zenvia360.com.br/services/send-sms', values, headers

			rescue Exception => e
				logger.error e.message
			end
		end
	end

end
