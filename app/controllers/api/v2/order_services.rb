module Api
  module V2
    class OrderServices < Grape::API
      resource :order_services do
        before { authenticate! }

        desc 'Lista ordens de serviço'
        params do
          optional :page, type: Integer, default: 1
          optional :per_page, type: Integer, default: 20
          optional :status_id, type: Integer
          optional :vehicle_id, type: Integer
          optional :search, type: String
        end
        get do
          user = current_user
          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id

          scope = OrderService.where(client_id: client_id)
          scope = scope.where(order_service_status_id: params[:status_id]) if params[:status_id].present?
          scope = scope.where(vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?

          if params[:search].present?
            search = "%#{params[:search]}%"
            scope = scope.joins(:vehicle).where(
              'order_services.code LIKE ? OR order_services.driver LIKE ? OR vehicles.board LIKE ?',
              search, search, search
            )
          end

          os_list = scope.includes(:vehicle, :order_service_status, :order_service_type, :provider)
                         .order(created_at: :desc)
                         .page(params[:page]).per(params[:per_page])

          {
            order_services: os_list.map { |os| serialize_os_summary(os) },
            meta: {
              current_page: os_list.current_page,
              total_pages: os_list.total_pages,
              total_count: os_list.total_count
            }
          }
        end

        desc 'Detalhes de uma OS'
        get ':id' do
          user = current_user
          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id
          os = OrderService.where(client_id: client_id).find(params[:id])

          proposals = os.order_service_proposals.includes(:provider, order_service_proposal_items: :service)

          {
            order_service: serialize_os_detail(os),
            proposals: proposals.map { |p| serialize_proposal(p) }
          }
        end

        desc 'Criar nova OS'
        params do
          requires :vehicle_id, type: Integer
          requires :provider_service_type_id, type: Integer
          optional :order_service_type_id, type: Integer, default: 1
          optional :km, type: Integer
          optional :driver, type: String
          requires :details, type: String
          optional :maintenance_plan_id, type: Integer
          optional :commitment_id, type: Integer
          optional :origin_type, type: String, default: 'mobile'
        end
        post do
          user = current_user
          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id
          vehicle = Vehicle.where(client_id: client_id).find(params[:vehicle_id])

          # Validar KM se necessário
          if params[:km].present?
            last_km = VehicleKmRecord.where(vehicle_id: vehicle.id).order(created_at: :desc).first
            if last_km && params[:km] < last_km.km
              error!("KM informado (#{params[:km]}) é menor que o último registro (#{last_km.km})", 422)
            end
          end

          os = OrderService.new(
            client_id: client_id,
            vehicle_id: params[:vehicle_id],
            provider_service_type_id: params[:provider_service_type_id],
            order_service_type_id: params[:order_service_type_id] || OrderServiceType::COTACOES_ID,
            order_service_status_id: OrderServiceStatus::EM_CADASTRO,
            km: params[:km],
            driver: params[:driver],
            details: params[:details],
            maintenance_plan_id: params[:maintenance_plan_id],
            commitment_id: params[:commitment_id],
            origin_type: params[:origin_type] || 'mobile'
          )

          if os.save
            # Registrar KM se informado
            if params[:km].present?
              VehicleKmRecord.create(
                vehicle_id: vehicle.id,
                user_id: user.id,
                order_service_id: os.id,
                km: params[:km],
                origin: 'order_service'
              )
            end

            { order_service: serialize_os_detail(os), message: 'OS criada com sucesso' }
          else
            error!(os.errors.full_messages.join(', '), 422)
          end
        end

        desc 'Aprovar OS (gestor/adicional)'
        put ':id/approve' do
          user = current_user
          unless user.profile_id.in?([Profile::GESTOR, Profile::ADICIONAL, Profile::ADMINISTRADOR])
            error!('Sem permissão para aprovar OS', 403)
          end

          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id
          os = OrderService.where(client_id: client_id).find(params[:id])

          if os.order_service_status_id == OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA
            os.update!(
              order_service_status_id: OrderServiceStatus::APROVADA,
              manager_id: user.id
            )

            # Aprovar proposta pendente
            pending_proposal = os.order_service_proposals
                                  .where(pending_manager_approval: true)
                                  .first
            if pending_proposal
              pending_proposal.update!(
                pending_manager_approval: false,
                order_service_proposal_status_id: OrderServiceProposalStatus::APROVADA
              )
            end

            { order_service: serialize_os_detail(os), message: 'OS aprovada com sucesso' }
          else
            error!("OS não está aguardando aprovação (status atual: #{os.order_service_status&.name})", 422)
          end
        end

        desc 'Rejeitar OS (gestor/adicional)'
        params do
          requires :justification, type: String
        end
        put ':id/reject' do
          user = current_user
          unless user.profile_id.in?([Profile::GESTOR, Profile::ADICIONAL, Profile::ADMINISTRADOR])
            error!('Sem permissão para rejeitar OS', 403)
          end

          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id
          os = OrderService.where(client_id: client_id).find(params[:id])

          os.update!(
            order_service_status_id: OrderServiceStatus::CANCELADA,
            cancel_justification: params[:justification]
          )

          { order_service: serialize_os_detail(os), message: 'OS rejeitada' }
        end

        desc 'Lista status disponíveis'
        get 'statuses/all' do
          statuses = OrderServiceStatus.all.map { |s| { id: s.id, name: s.name } }
          { statuses: statuses }
        end

        desc 'Lista tipos de serviço do fornecedor'
        get 'service_types/all' do
          types = ProviderServiceType.all.map { |t| { id: t.id, name: t.name } }
          { service_types: types }
        end
      end

      helpers do
        def serialize_os_summary(os)
          {
            id: os.id,
            code: os.code,
            status: os.order_service_status&.name,
            status_id: os.order_service_status_id,
            vehicle_board: os.vehicle&.board,
            vehicle_model: os.vehicle&.model,
            driver: os.driver,
            km: os.km,
            type: os.order_service_type&.name,
            provider: os.provider&.fantasy_name || os.provider&.name,
            created_at: os.created_at,
            updated_at: os.updated_at
          }
        end

        def serialize_os_detail(os)
          {
            id: os.id,
            code: os.code,
            status: os.order_service_status&.name,
            status_id: os.order_service_status_id,
            vehicle: {
              id: os.vehicle&.id,
              board: os.vehicle&.board,
              brand: os.vehicle&.brand,
              model: os.vehicle&.model,
              year: os.vehicle&.year
            },
            driver: os.driver,
            km: os.km,
            details: os.details,
            type: os.order_service_type&.name,
            type_id: os.order_service_type_id,
            provider: os.provider ? { id: os.provider.id, name: os.provider.fantasy_name || os.provider.name } : nil,
            service_type: os.provider_service_type&.name,
            commitment: os.commitment ? { id: os.commitment.id, number: os.commitment.commitment_number } : nil,
            maintenance_plan: os.maintenance_plan ? { id: os.maintenance_plan.id, name: os.maintenance_plan.name } : nil,
            cancel_justification: os.cancel_justification,
            origin_type: os.origin_type,
            created_at: os.created_at,
            updated_at: os.updated_at
          }
        end

        def serialize_proposal(p)
          {
            id: p.id,
            code: p.code,
            status: p.order_service_proposal_status&.name,
            status_id: p.order_service_proposal_status_id,
            provider: p.provider ? { id: p.provider.id, name: p.provider.fantasy_name || p.provider.name } : nil,
            total_value: p.total_value&.to_f,
            total_discount: p.total_discount&.to_f,
            is_complement: p.is_complement,
            pending_approval: p.pending_manager_approval,
            pending_authorization: p.pending_manager_authorization,
            items: p.order_service_proposal_items.map { |item|
              {
                id: item.id,
                service_name: item.service&.name,
                quantity: item.quantity,
                unit_value: item.unit_value&.to_f,
                total_value: item.total_value&.to_f,
                discount: item.discount&.to_f
              }
            },
            created_at: p.created_at
          }
        end
      end
    end
  end
end
