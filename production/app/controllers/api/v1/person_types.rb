module Api  
  module V1
    class PersonTypes < Grape::API
      include Api::V1::Defaults

      resource :person_types do

        #GET /person_types
        get "" do
          PersonType.all
        end

        #GET /person_types/:id
        params do
          requires :id
        end
        get ":id" do
          status 404
          status 200
          PersonType.where(id: permitted_params[:id]).first!
        end

      end  
    end
  end
end