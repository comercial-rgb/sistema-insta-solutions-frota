module Api  
  module V1
    class SiteContactSubjects < Grape::API
      include Api::V1::Defaults

      resource :site_contact_subjects do

        #GET /site_contact_subjects
        get "" do
          SiteContactSubject.all
        end

        #GET /site_contact_subjects/:id
        params do
          requires :id
        end
        get ":id" do
          status 404
          status 200
          SiteContactSubject.where(id: permitted_params[:id]).first!
        end

      end  
    end
  end
end
