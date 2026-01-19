module Api  
  module V1
    class Phones < Grape::API
      include Api::V1::Defaults

      resource :phones do

        #POST /phones
        post "" do
          authenticate!
          @phone = Phone.new(params)
          @phone.ownertable = @current_user
          if @phone.save
            {status: 'success', phone: @phone}
          else
            {status: 'failed', errors: @phone.errors, errors_message: @phone.errors.full_messages.join('<br>')}
          end
        end

        #GET /phones
        paginate
        get "" do
          authenticate!
          @current_user.phones.page(params[:page])
        end

        #GET /phones/:id
        params do
          requires :id
        end
        get "/:id" do
          authenticate!
          @phone = @current_user.phones.where(id: params[:id]).first
          if !@phone.nil?
            @phone
          else
            []
          end
        end

        #PUT /phones/:id
        params do
          requires :id
        end
        put "/:id" do
          authenticate!
          @phone = @current_user.phones.where(id: params[:id]).first
          if !@phone.nil?
            @phone.update(params)
            if @phone.valid?
              {status: 'success', phone: @phone}
            else
              {status: 'failed', errors: @phone.errors, errors_message: @phone.errors.full_messages.join('<br>')}
            end
          else
            {status: 'failed', errors: Phone.model_name.human+" "+I18n.t("model.not_found").downcase}
          end
        end

        #DELETE /phones/:id
        params do
          requires :id
        end
        delete "/:id" do
          authenticate!
          @phone = @current_user.phones.where(id: params[:id]).first
          if !@phone.nil?
            if @phone.destroy
              {status: 'success'}
            else
              {status: 'failed'}
            end
          else
            {status: 'failed', errors: Phone.model_name.human+" "+I18n.t("model.not_found").downcase}
          end
        end

      end

    end
  end
end