module Api
  module V2
    class MaintenanceAlerts < Grape::API
      resource :maintenance_alerts do
        before { authenticate! }

        desc 'Lista alertas de manutenção'
        params do
          optional :status, type: String, values: MaintenanceAlert::STATUSES
          optional :vehicle_id, type: Integer
          optional :page, type: Integer, default: 1
          optional :per_page, type: Integer, default: 20
        end
        get do
          user = current_user
          client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id

          scope = MaintenanceAlert.where(client_id: client_id)
          scope = scope.where(status: params[:status]) if params[:status].present?
          scope = scope.where(vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?

          alerts = scope.includes(:vehicle, :maintenance_plan_item)
                        .recent
                        .page(params[:page]).per(params[:per_page])

          {
            alerts: alerts.map { |a| serialize_alert(a) },
            pending_count: MaintenanceAlert.where(client_id: client_id).pending.count,
            meta: {
              current_page: alerts.current_page,
              total_pages: alerts.total_pages,
              total_count: alerts.total_count
            }
          }
        end

        desc 'Reconhecer alerta'
        put ':id/acknowledge' do
          user = current_user
          client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id
          alert = MaintenanceAlert.where(client_id: client_id).find(params[:id])

          alert.acknowledge!(user)
          { alert: serialize_alert(alert), message: 'Alerta reconhecido' }
        end

        desc 'Dispensar alerta'
        put ':id/dismiss' do
          user = current_user
          client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id
          alert = MaintenanceAlert.where(client_id: client_id).find(params[:id])

          alert.dismiss!
          { alert: serialize_alert(alert), message: 'Alerta dispensado' }
        end

        desc 'Forçar verificação de alertas'
        post 'check' do
          user = current_user
          client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id

          MaintenanceAlertService.check_all_vehicles(client_id)
          { message: 'Verificação de alertas concluída' }
        end

        desc 'Criar OS a partir do alerta (aprovação do gestor)'
        post ':id/create_os' do
          user = current_user
          unless [Profile::MANAGER_ID, Profile::ADDITIONAL_ID, Profile::ADMIN_ID].include?(user.profile_id)
            error!('Acesso negado', 403)
          end

          client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id
          alert = MaintenanceAlert.where(client_id: client_id).find(params[:id])

          if alert.status == 'completed' && alert.order_service_id.present?
            return { alert: serialize_alert(alert), order_service_id: alert.order_service_id, message: 'OS já foi criada para este alerta' }
          end

          plan_item = alert.maintenance_plan_item
          vehicle = alert.vehicle

          os = OrderService.new(
            vehicle_id: vehicle.id,
            client_id: vehicle.client_id,
            order_service_type_id: OrderServiceType::REQUISICAO_ID,
            order_service_status_id: OrderServiceStatus::EM_ABERTO_ID,
            maintenance_plan_id: plan_item.maintenance_plan_id,
            details: "OS gerada a partir do alerta de manutenção: #{alert.message}",
            km: alert.current_km || 0
          )

          unless os.save
            error!(os.errors.full_messages.join(', '), 422)
          end

          plan_item.maintenance_plan_item_services.each do |item_service|
            PartServiceOrderService.create(
              order_service_id: os.id,
              service_id: item_service.service_id,
              quantity: item_service.quantity,
              observation: item_service.observation
            )
          end

          alert.update!(status: 'completed', order_service_id: os.id)

          { alert: serialize_alert(alert), order_service_id: os.id, message: 'OS criada com sucesso' }
        end
      end

      helpers do
        def serialize_alert(a)
          {
            id: a.id,
            alert_type: a.alert_type,
            status: a.status,
            message: a.message,
            current_km: a.current_km,
            target_km: a.target_km,
            target_date: a.target_date,
            vehicle: {
              id: a.vehicle&.id,
              board: a.vehicle&.board,
              model: a.vehicle&.model
            },
            plan_item: a.maintenance_plan_item ? {
              id: a.maintenance_plan_item.id,
              name: a.maintenance_plan_item.name,
              plan_type: a.maintenance_plan_item.plan_type
            } : nil,
            acknowledged_at: a.acknowledged_at,
            order_service_id: a.order_service_id,
            created_at: a.created_at
          }
        end
      end
    end
  end
end
