module Api  
  module V1
    class Sexes < Grape::API
      include Api::V1::Defaults

      resource :sexes do

        #GET /sexes
        get "" do
          Sex.all
        end

        #GET /sexes/:id
        params do
          requires :id
        end
        get ":id" do
          status 404
          status 200
          Sex.where(id: permitted_params[:id]).first!
        end

      end  
    end
  end
end