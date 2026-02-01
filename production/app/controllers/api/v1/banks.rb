module Api  
  module V1
    class Banks < Grape::API
      include Api::V1::Defaults

      resource :banks do

        #GET /banks
        get "" do
          Bank.all
        end

        #GET /banks/:id
        params do
          requires :id
        end
        get ":id" do
          status 404
          status 200
          Bank.where(id: permitted_params[:id]).first!
        end

      end  
    end
  end
end