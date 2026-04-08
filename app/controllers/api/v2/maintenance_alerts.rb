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
          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id

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
          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id
          alert = MaintenanceAlert.where(client_id: client_id).find(params[:id])

          alert.acknowledge!(user)
          { alert: serialize_alert(alert), message: 'Alerta reconhecido' }
        end

        desc 'Dispensar alerta'
        put ':id/dismiss' do
          user = current_user
          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id
          alert = MaintenanceAlert.where(client_id: client_id).find(params[:id])

          alert.dismiss!
          { alert: serialize_alert(alert), message: 'Alerta dispensado' }
        end

        desc 'Forçar verificação de alertas'
        post 'check' do
          user = current_user
          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id

          MaintenanceAlertService.check_all_vehicles(client_id)
          { message: 'Verificação de alertas concluída' }
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
            created_at: a.created_at
          }
        end
      end
    end
  end
end
