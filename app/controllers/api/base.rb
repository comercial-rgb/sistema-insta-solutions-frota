module Api  
	class Base < Grape::API

		helpers do
			def authenticate!
				error!('Sem autorização. Token inválido ou expirado.', 401) unless current_user
			end

			def only_admin!
				error!('Sem autorização. Acesso apenas para administradores.', 401) unless only_admin
			end

			def current_user
				token_header = request.headers["Authorization"]
				token = ApiKey.where(access_token: token_header).first
				
				if token && !token.expired?
					@current_user = User.where(id: token.user_id).first
				else
					return false
				end
			end

			def only_admin
				token_header = request.headers["Authorization"]
				token = ApiKey.where(access_token: token_header).first
				
				if token && !token.expired?
					user = User.where(id: token.user_id).first
					if user && user.admin?
						return true
					else
						return false
					end
				else
					return false
				end
			end
		end

		mount Api::V1::Base
	end
end  