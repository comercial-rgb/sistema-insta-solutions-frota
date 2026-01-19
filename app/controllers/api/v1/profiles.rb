module Api  
  module V1
    class Profiles < Grape::API
      include Api::V1::Defaults

      resource :profiles do

        #GET /profiles
        get "" do
          Profile.all
        end

        #GET /profiles/:id
        params do
          requires :id
        end
        get ":id" do
          status 404
          status 200
          Profile.where(id: permitted_params[:id]).first!
        end

      end  
    end
  end
end