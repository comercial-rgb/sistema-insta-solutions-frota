module Api  
  module V1
    class Countries < Grape::API
      include Api::V1::Defaults

      resource :countries do

        #GET /countries
        get "" do
          Country.all
        end

        #GET /countries/:id
        params do
          requires :id
        end
        get ":id" do
          status 404
          status 200
          Country.where(id: permitted_params[:id]).first!
        end

      end  
    end
  end
end