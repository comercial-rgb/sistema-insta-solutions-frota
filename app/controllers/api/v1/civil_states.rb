module Api  
  module V1
    class CivilStates < Grape::API
      include Api::V1::Defaults

      resource :civil_states do

        #GET /civil_states
        get "" do
          CivilState.all
        end

        #GET /civil_states/:id
        params do
          requires :id
        end
        get ":id" do
          status 404
          status 200
          CivilState.where(id: permitted_params[:id]).first!
        end

      end  
    end
  end
end