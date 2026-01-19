class CepController < ApplicationController
	skip_before_action :authenticate_user

	def find_cep
    service = Utils::Cep::CepService.new(cep_params)
    address = service.call

		data = {
			address: address
		}

    # Encaminha a resposta
    respond_to do |format|
    	format.json {render :json => data, :status => 200}
    end
	end

  private

  def cep_params
    params.require(:cep)
  end
end
