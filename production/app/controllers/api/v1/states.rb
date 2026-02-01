module Api  
  module V1
    class States < Grape::API
      include Api::V1::Defaults

      resource :states do

        #GET /states
        get "" do
          State.all
        end

        #GET /states/:id
        params do
          requires :id
        end
        get ":id" do
          status 404
          status 200
          State.where(id: permitted_params[:id]).first!
        end

      end  
    end
  end
end