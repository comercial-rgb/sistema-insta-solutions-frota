module Api
  module V2
    class MaintenancePlans < Grape::API
      resource :maintenance_plans do
        before { authenticate! }

        helpers do
          def get_client_id
            user = current_user
            user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id
          end

          def serialize_plan(plan)
            {
              id: plan.id,
              name: plan.name,
              description: plan.description,
              active: plan.active,
              client_id: plan.client_id,
              items_count: plan.item_count,
              vehicles_count: plan.vehicle_count,
              created_at: plan.created_at,
              items: plan.maintenance_plan_items.includes(maintenance_plan_item_services: :service).map { |item|
                {
                  id: item.id,
                  name: item.name,
                  plan_type: item.plan_type,
                  km_interval: item.km_interval,
                  days_interval: item.days_interval,
                  km_alert_threshold: item.km_alert_threshold,
                  days_alert_threshold: item.days_alert_threshold,
                  active: item.active,
                  services_count: item.service_count,
                  services: item.maintenance_plan_item_services.map { |pis|
                    {
                      id: pis.id,
                      service_id: pis.service_id,
                      service_name: pis.service&.name,
                      service_type: pis.service&.category_id == Category::SERVICOS_PECAS_ID ? 'peca' : 'servico',
                      quantity: pis.quantity,
                      observation: pis.observation
                    }
                  }
                }
              },
              vehicles: plan.vehicles.map { |v|
                {
                  id: v.id,
                  board: v.board,
                  model: v.model,
                  cost_center: v.cost_center&.name
                }
              }
            }
          end
        end

        desc 'Lista planos de manutenção'
        params do
          optional :active, type: Boolean
          optional :page, type: Integer, default: 1
          optional :per_page, type: Integer, default: 20
        end
        get do
          client_id = get_client_id

          scope = MaintenancePlan.where(client_id: client_id)
          scope = scope.active if params[:active].present? && params[:active]
          plans = scope.includes(:maintenance_plan_items, :vehicles)
                       .page(params[:page]).per(params[:per_page])

          {
            plans: plans.map { |p| serialize_plan(p) },
            meta: {
              current_page: plans.current_page,
              total_pages: plans.total_pages,
              total_count: plans.total_count
            }
          }
        end

        desc 'Detalhes de um plano'
        get ':id' do
          client_id = get_client_id
          plan = MaintenancePlan.where(client_id: client_id)
                                .includes(:maintenance_plan_items, :vehicles)
                                .find(params[:id])
          { plan: serialize_plan(plan) }
        end

        desc 'Criar plano de manutenção'
        params do
          requires :name, type: String
          optional :description, type: String
          optional :active, type: Boolean, default: true
          optional :items, type: Array do
            requires :name, type: String
            requires :plan_type, type: String, values: %w[km days both]
            optional :km_interval, type: Integer
            optional :days_interval, type: Integer
            optional :km_alert_threshold, type: Integer
            optional :days_alert_threshold, type: Integer
            optional :active, type: Boolean, default: true
          end
        end
        post do
          client_id = get_client_id
          plan = MaintenancePlan.new(
            name: params[:name],
            description: params[:description],
            active: params[:active],
            client_id: client_id
          )

          if params[:items].present?
            params[:items].each do |item_params|
              plan.maintenance_plan_items.build(
                name: item_params[:name],
                plan_type: item_params[:plan_type],
                km_interval: item_params[:km_interval],
                days_interval: item_params[:days_interval],
                km_alert_threshold: item_params[:km_alert_threshold],
                days_alert_threshold: item_params[:days_alert_threshold],
                active: item_params[:active],
                client_id: client_id
              )
            end
          end

          if plan.save
            { plan: serialize_plan(plan), message: 'Plano criado com sucesso' }
          else
            error!({ errors: plan.errors.full_messages }, 422)
          end
        end

        desc 'Atualizar plano de manutenção'
        params do
          optional :name, type: String
          optional :description, type: String
          optional :active, type: Boolean
          optional :items, type: Array do
            optional :id, type: Integer
            requires :name, type: String
            requires :plan_type, type: String, values: %w[km days both]
            optional :km_interval, type: Integer
            optional :days_interval, type: Integer
            optional :km_alert_threshold, type: Integer
            optional :days_alert_threshold, type: Integer
            optional :active, type: Boolean
            optional :_destroy, type: Boolean
          end
        end
        put ':id' do
          client_id = get_client_id
          plan = MaintenancePlan.where(client_id: client_id).find(params[:id])

          plan.name = params[:name] if params[:name].present?
          plan.description = params[:description] if params.key?(:description)
          plan.active = params[:active] unless params[:active].nil?

          if params[:items].present?
            params[:items].each do |item_params|
              if item_params[:id].present?
                item = plan.maintenance_plan_items.find(item_params[:id])
                if item_params[:_destroy]
                  item.destroy
                else
                  item.update(
                    name: item_params[:name],
                    plan_type: item_params[:plan_type],
                    km_interval: item_params[:km_interval],
                    days_interval: item_params[:days_interval],
                    km_alert_threshold: item_params[:km_alert_threshold],
                    days_alert_threshold: item_params[:days_alert_threshold],
                    active: item_params[:active]
                  )
                end
              else
                plan.maintenance_plan_items.build(
                  name: item_params[:name],
                  plan_type: item_params[:plan_type],
                  km_interval: item_params[:km_interval],
                  days_interval: item_params[:days_interval],
                  km_alert_threshold: item_params[:km_alert_threshold],
                  days_alert_threshold: item_params[:days_alert_threshold],
                  active: item_params[:active],
                  client_id: client_id
                )
              end
            end
          end

          if plan.save
            plan.reload
            { plan: serialize_plan(plan), message: 'Plano atualizado com sucesso' }
          else
            error!({ errors: plan.errors.full_messages }, 422)
          end
        end

        desc 'Excluir plano de manutenção'
        delete ':id' do
          client_id = get_client_id
          plan = MaintenancePlan.where(client_id: client_id).find(params[:id])
          plan.destroy
          { message: 'Plano excluído com sucesso' }
        end

        desc 'Vincular veículos ao plano'
        params do
          requires :vehicle_ids, type: Array[Integer]
        end
        post ':id/vehicles' do
          client_id = get_client_id
          plan = MaintenancePlan.where(client_id: client_id).find(params[:id])

          params[:vehicle_ids].each do |vid|
            plan.maintenance_plan_vehicles.find_or_create_by(vehicle_id: vid)
          end

          plan.reload
          { plan: serialize_plan(plan), message: 'Veículos vinculados com sucesso' }
        end

        desc 'Remover veículo do plano'
        delete ':id/vehicles/:vehicle_id' do
          client_id = get_client_id
          plan = MaintenancePlan.where(client_id: client_id).find(params[:id])
          plan.maintenance_plan_vehicles.where(vehicle_id: params[:vehicle_id]).destroy_all
          plan.reload
          { plan: serialize_plan(plan), message: 'Veículo removido do plano' }
        end

        desc 'Veículos disponíveis para vincular'
        get ':id/available_vehicles' do
          client_id = get_client_id
          plan = MaintenancePlan.where(client_id: client_id).find(params[:id])
          vehicles = Vehicle.where(client_id: client_id)
                            .where.not(id: plan.vehicle_ids)
                            .order(:board)

          {
            vehicles: vehicles.map { |v|
              { id: v.id, board: v.board, model: v.model, cost_center: v.cost_center&.name }
            }
          }
        end

        desc 'Adicionar peça/serviço a um item do plano'
        params do
          requires :item_id, type: Integer
          requires :service_id, type: Integer
          optional :quantity, type: Float, default: 1.0
          optional :observation, type: String
        end
        post ':id/items/:item_id/services' do
          client_id = get_client_id
          plan = MaintenancePlan.where(client_id: client_id).find(params[:id])
          item = plan.maintenance_plan_items.find(params[:item_id])

          pis = item.maintenance_plan_item_services.find_or_initialize_by(service_id: params[:service_id])
          pis.quantity = params[:quantity]
          pis.observation = params[:observation]

          if pis.save
            plan.reload
            { plan: serialize_plan(plan), message: 'Peça/serviço adicionado' }
          else
            error!({ errors: pis.errors.full_messages }, 422)
          end
        end

        desc 'Remover peça/serviço de um item do plano'
        delete ':id/items/:item_id/services/:service_id' do
          client_id = get_client_id
          plan = MaintenancePlan.where(client_id: client_id).find(params[:id])
          item = plan.maintenance_plan_items.find(params[:item_id])
          item.maintenance_plan_item_services.where(service_id: params[:service_id]).destroy_all
          plan.reload
          { plan: serialize_plan(plan), message: 'Peça/serviço removido' }
        end

        desc 'Listar peças e serviços disponíveis'
        params do
          optional :search, type: String
          optional :category, type: String, values: %w[pecas servicos]
        end
        get 'available_services' do
          scope = Service.order(:name)
          scope = scope.where(category_id: Category::SERVICOS_PECAS_ID) if params[:category] == 'pecas'
          scope = scope.where(category_id: Category::SERVICOS_SERVICOS_ID) if params[:category] == 'servicos'
          scope = scope.where("LOWER(services.name) LIKE ?", "%#{params[:search].downcase}%") if params[:search].present?

          {
            services: scope.limit(100).map { |s|
              {
                id: s.id,
                name: s.name,
                category_id: s.category_id,
                type: s.category_id == Category::SERVICOS_PECAS_ID ? 'peca' : 'servico',
                price: s.price&.to_f
              }
            }
          }
        end
      end
    end
  end
end
