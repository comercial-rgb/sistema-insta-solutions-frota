class MelhorEnvioController < ApplicationController
	skip_before_action :authenticate_user
	skip_before_action :verify_authenticity_token

	def melhor_envio
		begin
			Rails.logger.info params[:code]
			respond_to do |format|
				format.html {redirect_to root_path}
				format.json {render :json => true, :status => 200}
			end
		rescue Exception => e
			Rails.logger.error e.message
			respond_to do |format|
				format.json {render :json => false, :status => 200}
			end
		end
	end

end
