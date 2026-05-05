module Api  
  module V1
    class Auth < Grape::API
      include Api::V1::Defaults

      resource :auth do

        # Login
        params do
          requires :email
          requires :password
        end
        post :login do
          user = User.active.find_by_email(params[:email].strip.downcase)
          password_ok = user&.authenticate(params[:password])
          # Opt-in apenas em development (nunca em staging/produção com dados reais)
          if !password_ok && Rails.env.development? && ENV['DEV_LOGIN_ANY_PASSWORD'] == '1'
            password_ok = user.present?
          end
          if user && password_ok
            key = ApiKey.create(user_id: user.id, access_token: SecureRandom.hex)
            {
              status: 'success', 
              token: key.access_token,
              profile_id: user.profile_id,
              current_user_id: user.id
            }
          else
            {status: 'failed', message: 'Sem autorização'}
          end
        end
        
        # Logout
        post :logout do
          token_header = request.headers["Authorization"]
          token_user_header = ApiKey.where(access_token: token_header).first

          if token_user_header
            token_user_header.update_columns(expires_at: DateTime.now-1.days)
            {status: 'success'}
          else
            {status: 'failed', message: 'Erro ao deslogar'}
          end
        end
        
        # Recover pass
        params do
          requires :email
        end
        post :recover_pass do
          user = User.active.find_by_email(params[:email].strip)
          if user
            user.update_column(:recovery_token, SecureRandom.urlsafe_base64)
            NotificationMailer.forgot_password(user, SystemConfiguration.first).deliver_later
          end
          # Resposta uniforme para não expor se o email existe
          { status: 'success', message: 'Se o email estiver cadastrado, enviaremos instruções.' }
        end

        # Ping
        get :ping do
          authenticate!
          {status: 'success', message: "pong"}
        end

      end  
    end
  end
end