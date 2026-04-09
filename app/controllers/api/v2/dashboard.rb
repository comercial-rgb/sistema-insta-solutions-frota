module Api
  module V2
    class Dashboard < Grape::API
      resource :dashboard do
        before { authenticate! }

        desc 'Retorna dados do dashboard para o usuário mobile'
        params do
          optional :client_id, type: Integer
        end
        get do
          user = current_user

          # Role-based scoping
          if user.admin?
            if params[:client_id].present?
              client_id = params[:client_id]
              os_scope = OrderService.where(client_id: client_id)
              vehicles_scope = Vehicle.where(client_id: client_id, active: true)
              anomalies_scope = Anomaly.where(client_id: client_id)
              alerts_scope = MaintenanceAlert.where(client_id: client_id)
            else
              os_scope = OrderService.all
              vehicles_scope = Vehicle.where(active: true)
              anomalies_scope = Anomaly.all
              alerts_scope = MaintenanceAlert.all
            end
          elsif user.provider?
            os_scope = OrderService.where(provider_id: user.id)
            vehicles_scope = Vehicle.none
            anomalies_scope = Anomaly.none
            alerts_scope = MaintenanceAlert.none
          else
            client_id = user.client?? user.id : user.client_id
            os_scope = OrderService.where(client_id: client_id)
            vehicles_scope = Vehicle.where(client_id: client_id, active: true)
            anomalies_scope = Anomaly.where(client_id: client_id)
            alerts_scope = MaintenanceAlert.where(client_id: client_id)

            # Gestor/Adicional: filter by cost center/sub unit
            if (user.manager? || user.additional?) && user.respond_to?(:associated_cost_centers)
              cc_ids = user.associated_cost_centers.pluck(:id)
              su_ids = user.associated_sub_units.pluck(:id)
              if cc_ids.present? || su_ids.present?
                vehicle_ids = Vehicle.where(client_id: client_id)
                vehicle_ids = vehicle_ids.where('cost_center_id IN (?) OR sub_unit_id IN (?)', cc_ids.presence || [0], su_ids.presence || [0])
                os_scope = os_scope.where(vehicle_id: vehicle_ids.select(:id))
                vehicles_scope = vehicles_scope.where('cost_center_id IN (?) OR sub_unit_id IN (?)', cc_ids.presence || [0], su_ids.presence || [0])
              end
            end
          end

          total_os = os_scope.count
          os_open = os_scope.where(order_service_status_id: [
            OrderServiceStatus::EM_ABERTO_ID,
            OrderServiceStatus::EM_CADASTRO_ID
          ]).count
          os_approved = os_scope.where(order_service_status_id: OrderServiceStatus::APROVADA_ID).count
          os_awaiting = os_scope.where(order_service_status_id: [
            OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID,
            OrderServiceStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
          ]).count
          os_paid = os_scope.where(order_service_status_id: OrderServiceStatus::PAGA_ID).count
          os_cancelled = os_scope.where(order_service_status_id: OrderServiceStatus::CANCELADA_ID).count

          vehicles_count = vehicles_scope.count
          anomalies_open = anomalies_scope.respond_to?(:open_anomalies) ? anomalies_scope.open_anomalies.count : 0
          pending_alerts = alerts_scope.respond_to?(:pending) ? alerts_scope.pending.count : 0

          # OS por mês (últimos 6 meses)
          os_by_month = os_scope
            .where('order_services.created_at >= ?', 6.months.ago)
            .group("DATE_FORMAT(order_services.created_at, '%Y-%m')")
            .count
            .map { |k, v| { month: k, count: v } }

          # Valores aprovados por tipo de serviço
          os_values_by_type = os_scope
            .joins(:order_service_type)
            .where(order_service_status_id: [
              OrderServiceStatus::APROVADA_ID,
              OrderServiceStatus::AUTORIZADA_ID,
              OrderServiceStatus::PAGA_ID
            ])
            .joins(order_service_proposals: :order_service_proposal_items)
            .group('order_service_types.name')
            .sum('order_service_proposal_items.total_value')
            .map { |k, v| { type: k, value: v.to_f } }

          client_id_resp = user.admin? ? nil : (user.client? ? user.id : user.client_id)

          {
            summary: {
              total_os: total_os,
              os_open: os_open,
              os_approved: os_approved,
              os_awaiting_approval: os_awaiting,
              os_paid: os_paid,
              os_cancelled: os_cancelled,
              vehicles_count: vehicles_count,
              anomalies_open: anomalies_open,
              pending_maintenance_alerts: pending_alerts
            },
            os_by_month: os_by_month,
            os_values_by_type: os_values_by_type,
            user: {
              id: user.id,
              name: user.name,
              email: user.email,
              profile_id: user.profile_id,
              profile_name: user.profile&.name,
              client_id: client_id_resp,
              client_name: user.admin? ? nil : (User.find_by(id: client_id_resp)&.fantasy_name),
              qr_nfc_enabled: user.respond_to?(:qr_nfc_enabled) ? user.qr_nfc_enabled : false
            }
          }
        end
      end
    end
  end
end
