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

          # Role-based scoping
          if user.admin?
            scope = OrderService.all
          elsif user.provider?
            scope = OrderService.where(provider_id: user.id)
              .or(OrderService.where(id: OrderServiceProposal.where(provider_id: user.id).select(:order_service_id)))
          else
            client_id = user.client? ? user.id : user.client_id
            scope = OrderService.where(client_id: client_id)

            if (user.manager? || user.additional?) && user.respond_to?(:associated_cost_centers)
              cc_ids = user.associated_cost_centers.pluck(:id)
              su_ids = user.associated_sub_units.pluck(:id)
              if cc_ids.present? || su_ids.present?
                vehicle_ids = Vehicle.where(client_id: client_id)
                  .where('cost_center_id IN (?) OR sub_unit_id IN (?)', cc_ids.presence || [0], su_ids.presence || [0])
                scope = scope.where(vehicle_id: vehicle_ids.select(:id))
              end
            end
          end
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

          if user.admin?
            os = OrderService.find(params[:id])
          elsif user.provider?
            os = OrderService.where(provider_id: user.id)
              .or(OrderService.where(id: OrderServiceProposal.where(provider_id: user.id).select(:order_service_id)))
              .find(params[:id])
          else
            client_id = user.client? ? user.id : user.client_id
            os = OrderService.where(client_id: client_id).find(params[:id])
          end

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
          optional :commitment_parts_id, type: Integer
          optional :commitment_services_id, type: Integer
          optional :client_id, type: Integer
          optional :manager_id, type: Integer
          optional :provider_id, type: Integer
          optional :service_group_id, type: Integer
          optional :origin_type, type: String, default: 'mobile'
        end
        post do
          user = current_user

          # Determine client_id based on role
          if user.admin?
            # Admin must specify client_id
            client_id = params[:client_id]
            error!('Admin deve informar o client_id', 422) unless client_id.present?
            vehicle = Vehicle.where(client_id: client_id).find(params[:vehicle_id])
          elsif user.client?
            client_id = user.id
            vehicle = Vehicle.where(client_id: client_id).find(params[:vehicle_id])
          else
            client_id = user.client_id
            vehicle = Vehicle.where(client_id: client_id).find(params[:vehicle_id])
          end

          # Determine manager_id
          manager_id = params[:manager_id]
          if manager_id.blank?
            manager_id = user.manager? || user.additional? ? user.id : nil
          end

          # Validar KM se necessário
          if params[:km].present?
            last_km = VehicleKmRecord.where(vehicle_id: vehicle.id).order(created_at: :desc).first
            if last_km && params[:km] < last_km.km
              error!("KM informado (#{params[:km]}) é menor que o último registro (#{last_km.km})", 422)
            end
          end

          os = OrderService.new(
            client_id: client_id,
            manager_id: manager_id,
            vehicle_id: params[:vehicle_id],
            provider_service_type_id: params[:provider_service_type_id],
            order_service_type_id: params[:order_service_type_id] || OrderServiceType::COTACOES_ID,
            order_service_status_id: OrderServiceStatus::EM_ABERTO_ID,
            km: params[:km],
            driver: params[:driver],
            details: params[:details],
            maintenance_plan_id: params[:maintenance_plan_id],
            commitment_id: params[:commitment_id],
            commitment_parts_id: params[:commitment_parts_id],
            commitment_services_id: params[:commitment_services_id],
            provider_id: params[:provider_id],
            service_group_id: params[:service_group_id],
            origin_type: params[:origin_type] || 'mobile',
            invoice_part_ir: 1.2,
            invoice_part_pis: 0.65,
            invoice_part_cofins: 3,
            invoice_part_csll: 1,
            invoice_service_ir: 4.8,
            invoice_service_pis: 0.65,
            invoice_service_cofins: 3,
            invoice_service_csll: 1
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
          unless user.profile_id.in?([Profile::MANAGER_ID, Profile::ADDITIONAL_ID, Profile::ADMIN_ID])
            error!('Sem permissão para aprovar OS', 403)
          end

          if user.admin?
            os = OrderService.find(params[:id])
          else
            client_id = user.client? ? user.id : user.client_id
            os = OrderService.where(client_id: client_id).find(params[:id])
          end

          if os.order_service_status_id == OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID
            os.update!(
              order_service_status_id: OrderServiceStatus::APROVADA_ID,
              manager_id: user.id
            )

            # Aprovar proposta pendente
            pending_proposal = os.order_service_proposals
                                  .where(pending_manager_approval: true)
                                  .first
            if pending_proposal
              pending_proposal.update!(
                pending_manager_approval: false,
                order_service_proposal_status_id: OrderServiceProposalStatus::APROVADA_ID
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
          unless user.profile_id.in?([Profile::MANAGER_ID, Profile::ADDITIONAL_ID, Profile::ADMIN_ID])
            error!('Sem permissão para rejeitar OS', 403)
          end

          if user.admin?
            os = OrderService.find(params[:id])
          else
            client_id = user.client? ? user.id : user.client_id
            os = OrderService.where(client_id: client_id).find(params[:id])
          end

          os.update!(
            order_service_status_id: OrderServiceStatus::CANCELADA_ID,
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

        desc 'Lista tipos de OS'
        get 'os_types/all' do
          types = OrderServiceType.all.map { |t| { id: t.id, name: t.name } }
          { os_types: types }
        end

        desc 'Lista planos de manutenção'
        get 'maintenance_plans/all' do
          user = current_user
          if user.admin?
            plans = MaintenancePlan.all
          else
            client_id = user.client? ? user.id : user.client_id
            plans = MaintenancePlan.where(client_id: client_id)
          end
          { maintenance_plans: plans.map { |p| { id: p.id, name: p.name } } }
        end

        desc 'Lista empenhos (commitments) disponíveis'
        get 'commitments/all' do
          user = current_user
          if user.admin?
            commitments = Commitment.where(active: true)
          else
            client_id = user.client? ? user.id : user.client_id
            commitments = Commitment.where(client_id: client_id, active: true)
          end
          { commitments: commitments.map { |c| { id: c.id, number: c.respond_to?(:commitment_number) ? c.commitment_number : c.id.to_s, name: c.respond_to?(:name) ? c.name : c.respond_to?(:commitment_number) ? c.commitment_number : "Empenho #{c.id}" } } }
        end

        desc 'Lista clientes (admin only)'
        get 'clients/all' do
          user = current_user
          if user.admin?
            clients = User.client.active.order(:fantasy_name)
            { clients: clients.map { |c| { id: c.id, name: c.fantasy_name.present? ? c.fantasy_name : c.name } } }
          else
            client_id = user.client? ? user.id : user.client_id
            client = User.find_by(id: client_id)
            { clients: client ? [{ id: client.id, name: client.fantasy_name.present? ? client.fantasy_name : client.name }] : [] }
          end
        end

        desc 'Lista gestores/managers'
        get 'managers/all' do
          user = current_user
          if user.admin?
            managers = User.where(profile_id: [Profile::MANAGER_ID, Profile::ADDITIONAL_ID]).active.order(:name)
          else
            client_id = user.client? ? user.id : user.client_id
            managers = User.where(profile_id: [Profile::MANAGER_ID, Profile::ADDITIONAL_ID], client_id: client_id).active.order(:name)
          end
          { managers: managers.map { |m| { id: m.id, name: m.name } } }
        end

        desc 'Lista grupos de serviço'
        get 'service_groups/all' do
          user = current_user
          if user.admin?
            groups = ServiceGroup.all
          elsif user.respond_to?(:client_id) && user.client_id.present?
            groups = ServiceGroup.where(client_id: user.client_id)
          else
            groups = ServiceGroup.where(client_id: user.id)
          end
          { service_groups: groups.map { |g| { id: g.id, name: g.name } } }
        rescue => e
          { service_groups: [] }
        end

        desc 'Lista fornecedores'
        get 'providers/all' do
          providers = User.provider.active.order(:fantasy_name)
          { providers: providers.map { |p| { id: p.id, name: p.fantasy_name.present? ? p.fantasy_name : p.name } } }
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
            type_id: os.order_service_type_id,
            provider: os.provider&.fantasy_name || os.provider&.name,
            client_name: os.client&.fantasy_name || os.client&.name,
            cost_center: os.vehicle&.cost_center&.name,
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
