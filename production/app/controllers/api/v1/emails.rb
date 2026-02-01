module Api  
  module V1
    class Emails < Grape::API
      include Api::V1::Defaults

      resource :emails do

        #POST /emails
        post "" do
          authenticate!
          @email = Email.new(params)
          @email.ownertable = @current_user
          if @email.save
            {status: 'success', email: @email}
          else
            {status: 'failed', errors: @email.errors, errors_message: @email.errors.full_messages.join('<br>')}
          end
        end

        #GET /emails
        paginate
        get "" do
          authenticate!
          @current_user.emails.page(params[:page])
        end

        #GET /emails/:id
        params do
          requires :id
        end
        get "/:id" do
          authenticate!
          @email = @current_user.emails.where(id: params[:id]).first
          if !@email.nil?
            @email
          else
            []
          end
        end

        #PUT /emails/:id
        params do
          requires :id
        end
        put "/:id" do
          authenticate!
          @email = @current_user.emails.where(id: params[:id]).first
          if !@email.nil?
            @email.update(params)
            if @email.valid?
              {status: 'success', email: @email}
            else
              {status: 'failed', errors: @email.errors, errors_message: @email.errors.full_messages.join('<br>')}
            end
          else
            {status: 'failed', errors: Email.model_name.human+" "+I18n.t("model.not_found").downcase}
          end
        end

        #DELETE /emails/:id
        params do
          requires :id
        end
        delete "/:id" do
          authenticate!
          @email = @current_user.emails.where(id: params[:id]).first
          if !@email.nil?
            if @email.destroy
              {status: 'success'}
            else
              {status: 'failed'}
            end
          else
            {status: 'failed', errors: Email.model_name.human+" "+I18n.t("model.not_found").downcase}
          end
        end

      end

    end
  end
end