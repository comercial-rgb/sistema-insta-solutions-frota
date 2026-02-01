module Api  
  module V1
    class AddressTypes < Grape::API
      include Api::V1::Defaults

      resource :address_types do

        #GET /address_types
        get "" do
          AddressType.all
        end

        #GET /address_types/:id
        params do
          requires :id
        end
        get ":id" do
          status 404
          status 200
          AddressType.where(id: permitted_params[:id]).first!
        end

      end  
    end
  end
end