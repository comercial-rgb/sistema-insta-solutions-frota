module Api  
  module V1
    class EmailTypes < Grape::API
      include Api::V1::Defaults

      resource :email_types do

        #GET /email_types
        get "" do
          EmailType.all
        end

        #GET /email_types/:id
        params do
          requires :id
        end
        get ":id" do
          status 404
          status 200
          EmailType.where(id: permitted_params[:id]).first!
        end

      end  
    end
  end
end