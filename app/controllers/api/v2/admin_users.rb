module Api
  module V2
    class AdminUsers < Grape::API
      resource :admin do
        before { authenticate! }

        namespace :users do
          desc 'Lista usuários do cliente (admin/gestor)'
          params do
            optional :page, type: Integer, default: 1
            optional :per_page, type: Integer, default: 20
            optional :profile_id, type: Integer
            optional :search, type: String
          end
          get do
            user = current_user
            unless user.profile_id.in?([Profile::ADMIN_ID, Profile::MANAGER_ID, Profile::CLIENT_ID])
              error!('Sem permissão para gerenciar usuários', 403)
            end

            client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id

            scope = User.where(client_id: client_id)
            scope = scope.where(profile_id: params[:profile_id]) if params[:profile_id].present?

            if params[:search].present?
              search = "%#{params[:search]}%"
              scope = scope.where('users.name LIKE ? OR users.email LIKE ? OR users.cpf LIKE ?', search, search, search)
            end

            users = scope.includes(:profile).order(:name).page(params[:page]).per(params[:per_page])

            {
              users: users.map { |u| serialize_user(u) },
              meta: {
                current_page: users.current_page,
                total_pages: users.total_pages,
                total_count: users.total_count
              }
            }
          end

          desc 'Detalhes de um usuário'
          get ':id' do
            user = current_user
            client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id
            target = User.where(client_id: client_id).find(params[:id])

            { user: serialize_user_detail(target) }
          end

          desc 'Criar usuário (gestor, adicional, motorista ou fornecedor)'
          params do
            requires :name, type: String
            requires :email, type: String
            requires :profile_id, type: Integer, desc: '2=Usuário, 4=Gestor, 5=Adicional, 6=Fornecedor'
            requires :password, type: String
            optional :cpf, type: String
            optional :cnpj, type: String
            optional :phone, type: String
            optional :cellphone, type: String
            optional :fantasy_name, type: String
            optional :department, type: String
            optional :registration, type: String
          end
          post do
            user = current_user
            unless user.profile_id.in?([Profile::ADMIN_ID, Profile::MANAGER_ID, Profile::CLIENT_ID])
              error!('Sem permissão para criar usuários', 403)
            end

            client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id

            # Apenas permite criar perfis subordinados
            allowed_profiles = [Profile::USER_ID, Profile::MANAGER_ID, Profile::ADDITIONAL_ID, Profile::PROVIDER_ID]
            unless params[:profile_id].in?(allowed_profiles)
              error!('Perfil não permitido', 422)
            end

            new_user = User.new(
              name: params[:name],
              email: params[:email],
              profile_id: params[:profile_id],
              password: params[:password],
              password_confirmation: params[:password],
              client_id: client_id,
              cpf: params[:cpf],
              cnpj: params[:cnpj],
              phone: params[:phone],
              cellphone: params[:cellphone],
              fantasy_name: params[:fantasy_name],
              department: params[:department],
              registration: params[:registration],
              user_status_id: 1
            )

            if new_user.save
              { user: serialize_user(new_user), message: 'Usuário criado com sucesso' }
            else
              error!(new_user.errors.full_messages.join(', '), 422)
            end
          end

          desc 'Atualizar usuário'
          params do
            optional :name, type: String
            optional :email, type: String
            optional :phone, type: String
            optional :cellphone, type: String
            optional :is_blocked, type: Boolean
            optional :os_blocked, type: Boolean
            optional :department, type: String
          end
          put ':id' do
            user = current_user
            unless user.profile_id.in?([Profile::ADMIN_ID, Profile::MANAGER_ID, Profile::CLIENT_ID])
              error!('Sem permissão', 403)
            end

            client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id
            target = User.where(client_id: client_id).find(params[:id])

            updates = declared(params, include_missing: false).except(:id)
            target.update!(updates)

            { user: serialize_user(target), message: 'Usuário atualizado' }
          end

          desc 'Bloquear/desbloquear usuário'
          put ':id/toggle_block' do
            user = current_user
            unless user.profile_id.in?([Profile::ADMIN_ID, Profile::MANAGER_ID, Profile::CLIENT_ID])
              error!('Sem permissão', 403)
            end

            client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id
            target = User.where(client_id: client_id).find(params[:id])

            target.update!(is_blocked: !target.is_blocked)
            status = target.is_blocked ? 'bloqueado' : 'desbloqueado'

            { user: serialize_user(target), message: "Usuário #{status}" }
          end
        end

        desc 'Perfis disponíveis para criação'
        get 'profiles' do
          profiles = Profile.where(id: [Profile::USER_ID, Profile::MANAGER_ID, Profile::ADDITIONAL_ID, Profile::PROVIDER_ID])
          { profiles: profiles.map { |p| { id: p.id, name: p.name } } }
        end
      end

      helpers do
        def serialize_user(u)
          {
            id: u.id,
            name: u.name,
            email: u.email,
            profile: u.profile&.name,
            profile_id: u.profile_id,
            cpf: u.cpf,
            phone: u.phone,
            cellphone: u.cellphone,
            is_blocked: u.is_blocked,
            os_blocked: u.os_blocked,
            department: u.department,
            created_at: u.created_at
          }
        end

        def serialize_user_detail(u)
          serialize_user(u).merge(
            cnpj: u.cnpj,
            fantasy_name: u.fantasy_name,
            registration: u.registration,
            state: u.state&.name,
            city: u.city&.name,
            needs_km: u.needs_km,
            require_vehicle_photos: u.require_vehicle_photos,
            updated_at: u.updated_at
          )
        end
      end
    end
  end
end
