module Api  
  module V1
    class Cities < Grape::API
      include Api::V1::Defaults

      resource :cities do

        #GET /cities
        get "" do
          City.all
        end

        #GET /cities/:id
        params do
          requires :id
        end
        get ":id" do
          City.find(permitted_params[:id])
        end

        #GET /cities/by_state/:state_id
        get "by_state/:state_id" do
          City.where(state_id: params[:state_id])
        end

      end  
    end
  end
end