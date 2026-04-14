module Api
  module V2
    class MobileBanners < Grape::API
      resource :mobile_banners do
        before { authenticate! }

        desc 'Retorna banners/dicas para exibição no dashboard mobile'
        get do
          user = current_user

          banners = OrientationManual.mobile_banners
                      .joins(:profiles)
                      .where(profiles: { id: user.profile_id })

          result = banners.map do |banner|
            {
              id: banner.id,
              type: banner.mobile_banner_type || 'tip',
              title: banner.mobile_banner_title.presence || banner.name,
              text: banner.mobile_banner_text.presence || banner.description,
              image_url: banner.mobile_banner_image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(banner.mobile_banner_image, only_path: true) : nil,
              document_url: banner.document.attached? ? Rails.application.routes.url_helpers.rails_blob_url(banner.document, disposition: 'attachment', only_path: true) : nil,
              order: banner.mobile_banner_order
            }
          end

          { banners: result }
        end
      end
    end
  end
end
