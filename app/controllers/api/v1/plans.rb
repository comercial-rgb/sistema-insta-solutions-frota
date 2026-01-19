module Api  
  module V1
    class Plans < Grape::API
      include Api::V1::Defaults

      resource :plans do

        #GET /plans
        paginate
        get "" do
          Plan.by_name(params[:name])
          .by_initial_price(params[:initial_price]).by_final_price(params[:final_price])
          .by_category_id(params[:category_id])
          .by_sub_category_id(params[:sub_category_id])
          .by_active(params[:active])
        end

        #GET /plans/:id
        params do
          requires :id
        end
        get ":id" do
          status 404
          status 200
          Plan.where(id: permitted_params[:id]).first!
        end

      end  
    end
  end
end