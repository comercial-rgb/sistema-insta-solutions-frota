module Api  
  module V1
    class CardBanners < Grape::API
      include Api::V1::Defaults

      resource :card_banners do

        #GET /card_banners
        get "" do
          CardBanner.all
        end

        #GET /card_banners/:id
        params do
          requires :id
        end
        get ":id" do
          status 404
          status 200
          CardBanner.where(id: permitted_params[:id]).first!
        end

      end  
    end
  end
end