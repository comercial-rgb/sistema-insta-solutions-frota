module Api  
  module V1
    class PhoneTypes < Grape::API
      include Api::V1::Defaults

      resource :phone_types do

        #GET /phone_types
        get "" do
          PhoneType.all
        end

        #GET /phone_types/:id
        params do
          requires :id
        end
        get ":id" do
          status 404
          status 200
          PhoneType.where(id: permitted_params[:id]).first!
        end

      end  
    end
  end
end