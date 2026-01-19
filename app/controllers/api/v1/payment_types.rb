module Api  
  module V1
    class PaymentTypes < Grape::API
      include Api::V1::Defaults

      resource :payment_types do

        #GET /payment_types
        get "" do
          PaymentType.all
        end

        #GET /payment_types/:id
        params do
          requires :id
        end
        get ":id" do
          status 404
          status 200
          PaymentType.where(id: permitted_params[:id]).first!
        end

      end  
    end
  end
end