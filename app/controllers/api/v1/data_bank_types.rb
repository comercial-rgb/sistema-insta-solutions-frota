module Api  
  module V1
    class DataBankTypes < Grape::API
      include Api::V1::Defaults

      resource :data_bank_types do

        #GET /data_bank_types
        get "" do
          DataBankType.all
        end

        #GET /data_bank_types/:id
        params do
          requires :id
        end
        get ":id" do
          status 404
          status 200
          DataBankType.where(id: permitted_params[:id]).first!
        end

      end  
    end
  end
end