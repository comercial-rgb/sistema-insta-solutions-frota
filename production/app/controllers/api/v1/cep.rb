module Api  
  module V1
    class Cep < Grape::API
      include Api::V1::Defaults

      resource :cep do

        #GET /get_address_by_cep
        params do
          requires :cep
        end
        get "/get_address_by_cep" do
          service = Utils::Cep::CepService.new(params[:cep])
          address = service.call
          if !address.nil? 
            state = State.where(acronym: address[:state]).first
            city = nil
            if state
              city = City.where(name: address[:city]).where(state_id: state.id).first
            end
            # Endereço / Estado / Cidade
            return {address: address, state: state, city: city}
          else
            # Não encontrou endereço
            return {status: 'Erro', message: 'Erro ao buscar endereço'}
          end
        end

      end  
    end
  end
end