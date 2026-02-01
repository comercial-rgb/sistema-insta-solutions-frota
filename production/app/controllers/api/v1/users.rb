module Api  
  module V1
    class Users < Grape::API
      include Api::V1::Defaults

      resource :users do

        #GET /users
        get "" do
          authenticate!
          @current_user
        end

        #POST /users
        post "" do
          @user = User.new(params)
          if @user.save
            @user.saving_profile_image_app
            key = ApiKey.create(user_id: @user.id, access_token: SecureRandom.hex)
            {
              status: 'success', 
              token: key.access_token,
              profile_id: @user.profile_id,
              current_user_id: @user.id
            }
          else
            {status: 'failed', errors: @user.errors, errors_message: @user.errors.full_messages.join('<br>')}
          end
        end

        #PUT /users
        put "" do
          authenticate!
          if @current_user
            @current_user.skip_validate_password = true
            @current_user.update(params)
            if @current_user.valid?
              @current_user.saving_profile_image_app
              {status: 'success'}
            else
              {status: 'failed', errors: @current_user.errors, errors_message: @current_user.errors.full_messages.join('<br>')}
            end
          else
            {status: 'failed', errors: {user: [User.model_name.human+' '+I18n.t('model.not_found')]}}
          end
        end

        #PUT /change_access_data
        put "/change_access_data" do
          authenticate!
          if @current_user
            if @current_user.authenticate(params[:current_password])
              @current_user.update(params)
              if @current_user.valid?
                {status: 'success'}
              else
                {status: 'failed', errors: @current_user.errors, errors_message: @current_user.errors.full_messages.join('<br>')}
              end
            else
              {status: 'failed', errors: User.human_attribute_name(:invalid_current_password), errors_message: User.human_attribute_name(:invalid_current_password)}
            end
          else
            {status: 'failed', errors: {user: [User.model_name.human+' '+I18n.t('model.not_found')]}}
          end
        end

        #DELETE /users
        delete ":id" do
          authenticate!
          @current_user
          if @current_user
            if @current_user.destroy
              {status: 'success'}
            else
              {status: 'failed', errors: @current_user.errors}
            end
          else
            {status: 'failed', errors: {user: [User.model_name.human+' '+I18n.t('model.not_found')]}}
          end
        end

      end

    end
  end
end